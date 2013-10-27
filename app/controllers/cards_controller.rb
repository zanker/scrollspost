class CardsController < ApplicationController
  helper_method :card_tooltip_data

  STAT_FILTERS = {"cost" => :total_cost, "hp" => :hp, "atk" => :attack, "cd" => :cd}
  SORT_KEYS = {"name" => [:name], "rarity" => [:rarity], "type" => [:category], "resource" => [:total_cost, :costs], "attack" => [:attack, :category], "hp" => [:hp, :category], "cooldown" => [:cooldown, :category], "rules" => [:passive_rule_ids], "buy-quantity" => [:"store.buy.total"], "buy-price" => [:"store.buy.min"], "sell-quantity" => [:"store.sell.total"], "sell-price" => [:"store.sell.min"], "updated-version" => [:last_game_version_id]}

  def tooltip
    last_mod = Rails.cache.read("card-data-cache")
    last_mod = last_mod ? Time.at(last_mod.to_i) : Time.now.utc
    cache_key = "card/tooltip/#{params[:card_id]}/#{last_mod}/#{Thread.current[:use_webp]}"
    return unless stale?(:public => true, :etag => cache_key, :last_modified => last_mod)

    data = Rails.cache.fetch(cache_key, :expires_in => 10.minutes) do
      card = Card.where(:card_id => params[:card_id].to_i).ignore(:pricing).first
      if card
        card_tooltip_data(card)
      else
        ""
      end
    end

    return render_404 if data.blank?

    render :json => data
  end

  def tooltips
    Thread.current[:use_webp] = params[:webp] == "1"

    last_mod = Rails.cache.read("card-data-cache") || Time.now.utc
    cache_key = "card/tooltips/#{last_mod}/#{Thread.current[:use_webp]}"

    expires_in(10.years, :public => true)
    return unless stale?(:public => true, :etag => cache_key, :last_modified => Time.at(last_mod))

    cards = Rails.cache.fetch(cache_key, :expires_in => 1.week) do
      Card.ignore(:store, *Card::PRICING_FIELDS.select {|k| k !~ /d7$/}, "pricing.d7.buy", "pricing.d7.sell").sort(:costs.asc, :total_cost.desc, :name.asc).map {|c| card_tooltip_data(c, true)}
    end

    render :js => "window.card_data = #{cards.to_json}"
  end

  def show_market
    load_card_data
    return unless @card

    @plot_bands, @buy_stats, @sell_stats, @unit_stats = Rails.cache.fetch("card-graphs/#{@card._id}/#{GameVersion.active_version}", :expires_in => 1.hour) do
      buy_series = {:price => [], :units => []}
      sell_series = {:price => [], :units => []}
      units_series = {:buy => [], :sell => []}

      sug_series = []
      CardPriceGraph.where(:card_id => @card._id, :type => CardPriceGraph::HOURLY, :created_at.gte => 14.days.ago.utc).sort(:created_at.asc).each do |graph|
        sug_series << [graph.created_at.to_i * 1000, view_context.round_number(graph.suggested || 0, 5)]

        buy_series[:price] << [graph.created_at.to_i * 1000, view_context.round_number(graph.buy || 0, 5)]
        units_series[:buy] << [graph.created_at.to_i * 1000, view_context.round_number(graph.buy_units || 0, 5)]

        sell_series[:price] << [graph.created_at.to_i * 1000, view_context.round_number(graph.sell || 0, 5)]
        units_series[:sell] << [graph.created_at.to_i * 1000, view_context.round_number(graph.sell_units || 0, 5)]
      end

      threshold = 7.days.ago.utc.to_i * 1000
      time_threshold = 24.hours.to_i * 1000
      [buy_series[:price], sell_series[:price], sug_series, units_series[:buy], units_series[:sell]].each do |points|
        last_time = points.last[0]

        # Strip anything older than a week
        points.delete_if {|v| v[0] < threshold or v[1] == 0}

        # Smooth the graph
        last = nil
        points.delete_if do |v|
          if last and v[1] == last[1]
            res = (v[0] - last[0]) < time_threshold
          end

          if !last or (v[0] - last[0]) > time_threshold
            last = v
          end

          res
        end

        # Add the last point if needed
        if !points.empty? and points.last[0] != last_time
          points.last[0] = last_time
        end
      end

      [buy_series[:price], sell_series[:price]].each do |points|
        if !points.empty? and !sug_series.empty?
          if points.first[0] > sug_series.first[0]
            points.insert(0, [sug_series.first[0], points[0][1]])
          end
        end
      end

      # Grab patch data
      bands = []
      GameVersion.where(:created_at.gte => 7.days.ago.utc).ignore(:log).each do |version|
        bands << {
          :from => version.created_at.to_i * 1000,
          :to => (version.created_at.to_i + 1.day) * 1000,
          :color => "rgba(186, 129, 6, 0.35)",
          :label => {
            :text => t("version", :version => version.version),
            :y => -10,
            :style => {:color => "#F3C90C"}
          }
        }
      end

      # Format for return
      buy_series[:suggested], sell_series[:suggested] = sug_series, sug_series
      [bands.to_json, buy_series.to_json, sell_series.to_json, units_series.to_json]
    end
  end

  def show_store
    load_card_data(true)
    return unless @card

    @accounts = {}
    @last_sells = UserInventory.where(:sell_quant.gt => 0, :card_id => @card._id, :public => true).only(:sell_quant, :sell_price, :scroll_account_id).sort(:updated_at.asc).limit(CONFIG[:limits][:trade]).map do |inventory|
      @accounts[inventory.scroll_account_id] = true
      inventory
    end

    @last_buys = UserInventory.where(:buy_quant.gt => 0, :card_id => @card._id, :public => true).only(:buy_quant, :buy_price, :scroll_account_id).sort(:updated_at.asc).limit(CONFIG[:limits][:trade]).map do |inventory|
      @accounts[inventory.scroll_account_id] = true
      inventory
    end

    ScrollAccount.where(:_id.in => @accounts.keys).only(:name).each do |account|
      @accounts[account._id] = account.name
    end
  end

  def show_chat
    load_card_data(true)
    return unless @card

    Redis.current.with do |r|
      @last_buys = r.lrange("clogs:#{@card._id}:#{CardPriceHistory::BUY}", 0, 15).map do |line|
        created_at, price, name, channel = line.split(",", 4)
        {:created_at => Time.at(created_at.to_i), :from => name, :room => channel, :price => price.to_i}
      end

      @last_sales = r.lrange("clogs:#{@card._id}:#{CardPriceHistory::SELL}", 0, 15).map do |line|
        created_at, price, name, channel = line.split(",", 4)
        {:created_at => Time.at(created_at.to_i), :from => name, :room => channel, :price => price.to_i}
      end
    end
  end

  def show
    load_card_data(true)
    return unless @card

    # Use an old version
    if params[:version]
      version_id = GameVersion.version_to_id(params[:version].gsub("-", "."))
      return render_404 if version_id.blank?

      @card_data = CardHistory.where(:live_card_id => @card._id, :game_version_id => version_id).sort(:created_desc).first
      return render_404 unless @card_data

      @live_card = @card
      @card = @card_data

      @game_version = params[:version].gsub("-", ".")

    # Use the live data
    else
      @card_data = @card
      @live_card = @card
    end

    # Grab any rules for the card
    @rules = {}
    if @card_data.passive_rule_ids?
      PassiveRule.where(:_id.in => @card_data.passive_rule_ids).each do |rule|
        @rules[rule._id] = rule
      end
    end

    # And grab its history
    @history = Rails.cache.fetch("card-history/#{@live_card._id}/#{@live_card.updated_at}", :expires_in => 1.week) do
      versions = {}

      rows = []
      CardHistory.where(:live_card_id => @live_card._id).only(:total_changes, :game_version_id, :created_at).sort(:created_at.desc).each do |history|
        # We only show the latest version intentionally
        next if versions[history.game_version_id]

        versions[history.game_version_id] = true

        rows << {:total_changes => history.total_changes, :game_version_id => history.game_version_id, :created_at => history.created_at}
      end

      GameVersion.where(:_id.in => versions.keys).ignore(:log).each do |version|
        versions[version._id] = version.version
      end

      rows.each do |row|
        row[:game_version] = versions[row.delete(:game_version_id)]
      end

      rows
    end
  end

  def index
    @filters = {:resources => {}, :rarities => {}}

    @cards = Card.where
    if SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      @cards = @cards.sort(*SORT_KEYS[params[:sort_by]].map {|key| key.send(params[:sort_mode])})

    else
      @cards = @cards.sort(:name.asc)
      params[:sort_by], params[:sort_mode] = "name", "asc"
    end

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

    # Stats
    STAT_FILTERS.each do |key, field|
      unless params["min_#{key}"].blank?
        @cards = @cards.where(field => {"$gte" => params["min_#{key}"].to_i})
      end

      unless params["max_#{key}"].blank?
        @cards = @cards.where(field => {"$lte" => params["max_#{key}"].to_i})
      end
    end

    # Load rules and such
    @rules = {}
    PassiveRule.only(:name, :slug).sort(:name.asc).each do |rule|
      @rules[rule._id] = {:name => rule.name, :slug => rule.slug}

      if params[:rule] == rule.slug
        @filters[:rule_id] = rule._id
        @cards = @cards.where(:passive_rule_ids => rule._id)
      end
    end

    @categories = {}
    Card::CATEGORY_MAP.each do |key, id|
      @categories[key] = {:name => t("categories.#{key}"), :slug => t("categories.#{key}").parameterize}

      if params[:category] == @categories[key][:slug]
        @filters[:category_id] = key
        @cards = @cards.where(:category => id)
      end
    end

    @game_versions = {}
    GameVersion.only(:version).each do |version|
      @game_versions[version._id] = version.version
    end
  end

  private
  def load_card_data(skip_cache=nil)
    @card = Card.where(:card_id => params[:card_id].to_i).first
    unless @card
      return render_404
    end

    unless skip_cache
      return unless stale?(:etag => "#{@card.cache_key}#{@card.price_updated_at.to_i}#{params[:action]}/#{params[:version]}")
    end
  end

  def load_rules_cache
    @rules_cache ||= Rails.cache.fetch("passive-rules-#{Rails.cache.read("card-data-cache")}", :expires_in => 1.week) do
      data = {}
      PassiveRule.only(:name, :slug).each {|r| data[r._id.to_s] = [r.name, r.slug]}
      data
    end
  end

  def card_tooltip_data(card, extended=false)
    load_rules_cache

    res = card.serializable_hash(:methods => [:category], :only => [:id, :name, :desc, :types, :flavor])
    if card.passive_rule_ids?
      res[:passive_rules] = card.passive_rule_ids.map {|id| @rules_cache[id.to_s][0]}
    else
      res[:passive_rules] = []
    end

    res[:images] = {}
    res[:images][:base] = view_context.image_path("raw/#{card.costs.first}_#{card.rarity_key}.png")
    res[:images][:costbg] = view_context.image_path("raw/cost.png")
    res[:images][:resource] = view_context.image_path("resources/#{card.costs.first}-28.png")
    res[:images][:cost] = view_context.image_path("raw/cost_#{card.total_cost}.png")
    res[:images][:card] = view_context.image_path("cards/large-#{card.image_id}.png")

    if extended
      res[:card_id] = card.card_id

      res[:price] = {}
      res[:price][:suggested] = card.pricing && card.pricing["d7"] && card.pricing["d7"]["sug"] || 0

      res[:images][:card_small] = view_context.image_path("cards/small-#{card.image_id}.png")

      res[:passive_rule_slugs] = []
      unless res[:passive_rules].empty?
        res[:passive_rule_slugs] = card.passive_rule_ids.map {|id| @rules_cache[id.to_s][1]}
      end

      res[:resources] = card.costs
      res[:rarity] = card.rarity

      res[:total_cost] = card.total_cost
      res[:stats] = {}
      if card.hp > 0 or card.cooldown > 0 or card.attack > 0
        res[:stats][:hp] = card.hp
        res[:stats][:cd] = card.cooldown if card.cooldown > 0
        res[:stats][:atk] = card.attack
      end
    end

    if card.hp > 0 or card.cooldown > 0 or card.attack > 0
      res[:images][:stat_hp] = view_context.image_path("raw/stat_#{card.hp}.png")
      res[:images][:stat_cd] = view_context.image_path("raw/stat_#{card.cooldown > 0 ? card.cooldown : "dash"}.png")
      res[:images][:stat_atk] = view_context.image_path("raw/stat_#{card.attack}.png")

      res[:images][:statsbg] = view_context.image_path("raw/stats.png")
    end

    res
  end
end