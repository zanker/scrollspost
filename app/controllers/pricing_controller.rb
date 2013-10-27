class PricingController < ApplicationController
  SORT_KEYS = {"sug-price" => "pricing.%s.sug", "buy-price" => "pricing.%s.buy.p95", "buy-popularity" => "pricing.%s.buy.total", "sell-price" => "pricing.%s.sell.p95", "sell-popularity" => "pricing.%s.sell.total", "updated-version" => "last_game_version_id"}
  STAT_PERIOD = {"1-hour" => "h1", "1-day" => "d1", "3-days" => "d3", "7-days" => "d7", "14-days" => "d14", "30-days" => "d30"}

  def index
    @cards = Card.where
    generic_store_filters

    # Stat period
    fields = [:costs, :name, :rarity, :price_seen_at, :image_id, :card_id, :cost_energy, :cost_growth, :cost_decay, :cost_order, :last_game_version_id]

    period = STAT_PERIOD[params[:period]] || "d1"
    fields << "pricing.#{period}"
    @period_key = period

    @cards = @cards.only(*fields)

    # Price Sorting
    if SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      sort_key = SORT_KEYS[params[:sort_by]] % @period_key
      @cards = @cards.sort(sort_key.to_sym.send(params[:sort_mode]))
    end

    return unless stale?(:etag => "2/#{request.path}/#{DEPLOY_ID}/#{Rails.cache.read("card-cache")}")
  end

  def chat
    @cards = {}
    Redis.current.with do |redis|
      @trade_chat = redis.lrange("clogs", 0, 100).map do |line|
        flag, card_id, created_at, price, name, channel = line.split(",", 6)

        @cards[card_id] = true
        {:created_at => Time.at(created_at.to_i), :from => name, :room => channel, :price => price.to_i, :flag => flag.to_i, :card_id => card_id}
      end
    end

    Card.where(:_id.in => @cards.keys).only(:costs, :name, :rarity, :image_id, :card_id, :cost_energy, :cost_growth, :cost_decay, :cost_order).each do |card|
      @cards[card._id.to_s] = card
    end
  end

  def store
    @cards = Card.where("$or" => [{"store.buy.total" => {"$gte" => 0}}, {"store.sell.total" => {"$gte" => 0}}])
    @cards = @cards.only(:name, :rarity, :costs, :cost_energy, :cost_growth, :cost_decay, :cost_order, :image_id, :card_id, :store)
    generic_store_filters
  end

  private
  def generic_store_filters
    if ::CardsController::SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      @cards = @cards.sort(*::CardsController::SORT_KEYS[params[:sort_by]].map {|key| key.send(params[:sort_mode])})
    elsif !SORT_KEYS[params[:sort_by]]
      @cards = @cards.sort(:name.asc)
      params[:sort_by], params[:sort_mode] = "name", "asc"
    end

    @filters = {:resources => {}, :rarities => {}}

    # Resources
    if params[:resources] != "all"
      params[:resources].split("-").each do |resource|
        if Card::RESOURCE_MAP[resource]
          @filters[:resources][resource] = true
        end
      end

      unless @filters[:resources].empty?
        @cards = @cards.where(:costs.in => @filters[:resources].keys)
      end
    else
      Card::RESOURCE_MAP.each_key {|k| @filters[:resources][k] = true}
    end

    # Rarities
    if params[:rarities] != "all"
      params[:rarities].split("-").each do |rarity|
        if Card::REVERSE_RARITY_MAP[rarity]
          @filters[:rarities][Card::REVERSE_RARITY_MAP[rarity]] = true
        end
      end

      unless @filters[:rarities].empty?
        @cards = @cards.where(:rarity.in => @filters[:rarities].keys)
      end
    else
      Card::RARITY_MAP.each_key {|k| @filters[:rarities][k] = true}
    end

    # Version
    unless params[:version].blank?
      id = GameVersion.version_to_id(params[:version].tr("-", "."))
      unless id.blank?
        @filters[:version_id] = BSON::ObjectId(id)
        @cards = @cards.where(:last_game_version_id => @filters[:version_id])
      end
    end

    # Categories
    @categories = {}
    Card::CATEGORY_MAP.each do |key, id|
      @categories[key] = {:name => t("categories.#{key}"), :slug => t("categories.#{key}").parameterize}

      if params[:category] == @categories[key][:slug]
        @filters[:category_id] = key
        @cards = @cards.where(:category => id)
      end
    end
  end
end