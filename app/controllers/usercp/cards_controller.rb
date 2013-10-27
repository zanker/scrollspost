class Usercp::CardsController < Usercp::BaseController
  def pricing
    unless period = PricingController::STAT_PERIOD[params[:period].to_s]
      return render_404
    end

    res = {}
    Card.only("pricing.#{period}.sug").each do |card|
      res[card._id] = view_context.round_number(card.pricing[period] && card.pricing[period]["sug"] || 0, 5)
    end

    render :json => res
  end

  def save_prices
    if params[:updates].is_a?(Hash)
      account_id = nil

      params[:updates].each do |card_id, changes|
        card_id = BSON::ObjectId.legal?(card_id) ? BSON::ObjectId(card_id) : nil
        next unless card_id

        to_set = {}
        to_set[:buy_quant] = changes["buy-quantity"].to_i if changes["buy-quantity"]
        to_set[:buy_price] = changes["buy"].to_i if changes["buy"]

        to_set[:sell_quant] = changes["sell-quantity"].to_i if changes["sell-quantity"]
        to_set[:sell_price] = changes["sell"].to_i if changes["sell"]
        to_set.delete_if {|k, v| v < 0}

        unless to_set.empty?
          to_set[:updated_at] = Time.now.utc

          res = UserInventory.set({:user_id => current_user._id, :card_id => card_id}, to_set)

          if res["n"] == 0
            account_id ||= ScrollAccount.where(:user_id => current_user._id).only(:_id).first._id
            UserInventory.create(to_set.merge(:quantity => 0, :deck_quant => 0, :user_id => current_user._id, :card_id => card_id, :scroll_account_id => account_id, :created_at => Time.now.utc, :updated_at => Time.now.utc))
          end
        end
      end
    end

    render :nothing => true, :status => :no_content
  end

  def index
    @inventory = {}
    UserInventory.where(:user_id => current_user._id).each do |inv|
      @inventory[inv.card_id] = inv
    end

    # Easiest way of getting sorted cards without re-embedding everything
    @sorted_cards = Card.only(:name, :rarity, :costs, :cost_energy, :cost_growth, :cost_decay, :cost_order, :image_id, :card_id)
    if ::CardsController::SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      @sorted_cards = @sorted_cards.sort(*::CardsController::SORT_KEYS[params[:sort_by]].map {|key| key.send(params[:sort_mode])})

    else
      @sorted_cards = @sorted_cards.sort(:name.asc)
      params[:sort_by], params[:sort_mode] = "name", "asc"
    end
  end
end