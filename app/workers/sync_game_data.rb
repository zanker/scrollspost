class SyncGameData
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  CARD_QUEUE = "card-queue"
  GAME_VERSION = "game-version"
  CHANGED_KEYS = ["name", "desc", "flavor", "types", "category", "rules", "passive_rule_ids", "ability_ids", "rarity", "hp", "attack", "cooldown", "cost_order", "cost_decay", "cost_energy", "cost_growth", "available", "target", "image_id", "anim_bundle_id", "anim_prev_img_id", "anim_prev_info"]

  def perform
    redis = Redis.current.checkout

    # Grab game version
    active_version = redis.multi do
      redis.get(GAME_VERSION)
      redis.del(GAME_VERSION)
    end.first

    return if active_version.blank?

    # New version out
    new_version = nil
    if active_version != GameVersion.active_version and !GameVersion.where(:internal_version => active_version).exists?
      Rails.cache.delete("active-version")
      Rails.cache.delete("active-version-id")

      version = GameVersion.create!(:version => active_version, :created_at => Time.now.utc)
      new_version = version._id
    end

    # Pull anything queued off the stack
    card_queue = redis.multi do
      redis.lrange(CARD_QUEUE, 0, 100_000)
      redis.del(CARD_QUEUE)
    end.first

    return if card_queue.empty?

    Rails.cache.delete("active-version")
    Rails.cache.delete("active-version-id")

    db_cards, redis_cards = {}, {}

    # Load the redis card data
    redis.multi do
      card_queue.each do |id|
        redis_cards[id.to_i] = redis.hgetall("card:#{id}")
      end
    end

    redis_cards.each {|id, future| redis_cards[id] = future.value}

    # Load what we have in the DB
    Card.where(:card_id.in => card_queue.map {|id| id.to_i}).each do |card|
      db_cards[card.card_id] = card
    end

    # Grab all the passive rules
    passive_rule_cache = {}
    PassiveRule.all.each do |rule|
      passive_rule_cache[rule.name.downcase] = rule
    end

    # Grab all the abilities
    ability_cache = {}
    Ability.all.each do |ability|
      ability_cache[ability.ability_id] = ability
    end

    # Start updating cards
    game_version_id = GameVersion.sort(:created_at.desc).limit(1).only(:_id).first._id.to_s
    last_version_id = GameVersion.where(:_id.ne => game_version_id).sort(:created_at.desc).limit(1).only(:_id).first._id

    card_changed = nil

    redis_cards.each do |card_id, data|
      # Quick check to see if anything changed
      card_hash = Digest::SHA1.digest(data.inspect)
      if db_cards[card_id] and db_cards[card_id].hash == card_hash
        next
      end

      card_changed = true

      # Log the old card so we can do historic records
      if db_cards[card_id]
        history = CardHistory.new(db_cards[card_id].attributes)
        history._id = BSON::ObjectId.new
        history.updated_at = Time.now.utc
        history.created_at = Time.now.utc
        history.game_version_id = last_version_id
        history.live_card_id = db_cards[card_id]._id
        history.save
      end

      card = db_cards[card_id] || Card.new(:card_id => card_id)
      card.hash = card_hash
      card.last_game_version_id = game_version_id
      card.added_game_version_id ||= game_version_id
      card.historic_game_version_ids << game_version_id

      card.rarity = data["rarity"].to_i
      card.available = data["avail"] == "true"

      card.types = data["types"].split(",")

      card.name = data["name"]
      card.desc = data["desc"].blank? ? nil : data["desc"]
      card.flavor = data["flav"].blank? ? nil : data["flav"]

      card.hp = data["hp"].to_i
      card.cooldown = data["cd"].to_i
      card.attack = data["atk"].to_i

      card.cost_order = data["c-order"].to_i
      card.cost_energy = data["c-energy"].to_i
      card.cost_growth = data["c-growth"].to_i
      card.cost_decay = data["c-decay"].to_i
      card.total_cost = card.cost_order + card.cost_energy + card.cost_growth + card.cost_decay

      card.costs = []
      Card::RESOURCE_MAP.each_key do |resource|
        card.costs << resource if data["c-#{resource}"].to_i > 0
      end

      card.target = data["target"]

      card.image_id = data["img"].to_i
      card.anim_bundle_id = data["animBundle"].to_i
      card.anim_prev_img_id = data["animPrevImg"].to_i
      card.anim_prev_info = data["animPrevInfo"].split(",").map {|num| num.to_f}

      card.rules = data["rules"].split(",")

      # Category
      # No attack/hp/cooldown, has to be an enchantment or spell
      if card.attack == 0 and card.hp == 0 and card.cooldown == 0
        # No target means enchantment for some reason
        card.category = card.target.blank? ? Card::CATEGORY_MAP["enchantment"] : Card::CATEGORY_MAP["spell"]
      # If it can move, it's a creature
      elsif card.rules.include?("Move")
        card.category = Card::CATEGORY_MAP["creature"]
      # Otherwise structure
      else
        card.category = Card::CATEGORY_MAP["structure"]
      end

      # Update passive rules
      card.passive_rule_ids = []
      if !data["passiveRules"].blank? and data["passiveRules"] != "null"
        list = MultiJson.load(data["passiveRules"])

        card.passive_rule_ids = list.map do |rule_data|
          rule = passive_rule_cache[rule_data["displayName"].downcase] ||= PassiveRule.new
          rule.name = rule_data["displayName"]
          rule.desc = rule_data["description"]
          rule.slug = rule_data["displayName"].parameterize
          # So we don't call updated_at without a real change
          rule.save if rule.changed?

          rule._id
        end
      end

      # Update abilities
      card.ability_ids = []
      if !data["abilities"].blank? and data["abilities"] != "null"
        list = MultiJson.load(data["abilities"])

        card.ability_ids = list.map do |ability_data|
          ability = ability_cache[ability_data["id"]] ||= Ability.new(:ability_id => ability_data["id"])

          ability.name = ability_data["name"]
          ability.desc = ability_data["description"]
          ability.cost_order = ability_data["ORDER"].to_i
          ability.cost_energy = ability_data["ENERGY"].to_i
          ability.cost_growth = ability_data["GROWTH"].to_i
          ability.cost_decay = ability_data["DECAY"].to_i
          ability.save if ability.changed?

          ability._id
        end
      end

      card.save

      # Figure out changes
      if history
        old_attribs, new_attribs = history.attributes, card.attributes

        changes = 0
        CHANGED_KEYS.each do |key|
          if new_attribs[key] != old_attribs[key]
            changes += 1
          end
        end

        history.total_changes = changes
        history.save
      end
    end

    # Clean up any card history data
    CardHistory.unset({}, :price_seen_at, :price_updated_at, :pricing, :store, :store_updated_at)

    Rails.cache.write("card-cache", Time.now.to_i)

    if card_changed
      Rails.cache.write("card-data-cache", Time.now.to_i)
    end

    # Parse news
    if new_version
      ParseNews.perform_async(new_version)
    end

  ensure
    Redis.current.checkin
  end
end