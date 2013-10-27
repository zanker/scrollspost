class StoreController < ApplicationController
  def show
    @account = ScrollAccount.where(:_id => BSON::ObjectId.base36_decode(params[:account_id].to_s)).first
    if !@account or ( !@account.public? and ( !current_user or current_user._id != @account.user_id ) )
      return render_404
    end

    @sell_cards, @buy_cards, @card_ids = {}, {}, []
    UserInventory.where(:scroll_account_id => @account._id, "$or" => [{:sell_quant.gt => 0}, {:buy_quant.gt => 0}]).each do |inventory|
      @card_ids << inventory.card_id

      if inventory.sell_quant and inventory.sell_quant > 0
        @sell_cards[inventory.card_id] = inventory
      end

      if inventory.buy_quant and inventory.buy_quant > 0
        @buy_cards[inventory.card_id] = inventory
      end
    end

    if @card_ids.empty?
      @sorted_cards = []
      @categories, @filters = {}, {:resources => {}, :rarities => {}}

    else
      @sorted_cards = Card.where(:_id.in => @card_ids).only(:name, :rarity, :costs, :cost_energy, :cost_growth, :cost_decay, :cost_order, :image_id, :card_id)
      if ::CardsController::SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
        @sorted_cards = @sorted_cards.sort(*::CardsController::SORT_KEYS[params[:sort_by]].map {|key| key.send(params[:sort_mode])})

      else
        @sorted_cards = @sorted_cards.sort(:name.asc)
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
          @sorted_cards = @sorted_cards.where(:costs.in => @filters[:resources].keys)
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
          @sorted_cards = @sorted_cards.where(:rarity.in => @filters[:rarities].keys)
        end
      else
        Card::RARITY_MAP.each_key {|k| @filters[:rarities][k] = true}
      end

      # Categories
      @categories = {}
      Card::CATEGORY_MAP.each do |key, id|
        @categories[key] = {:name => t("categories.#{key}"), :slug => t("categories.#{key}").parameterize}

        if params[:category] == @categories[key][:slug]
          @filters[:category_id] = key
          @sorted_cards = @sorted_cards.where(:category => id)
        end
      end

    end
  end
end