class Api::V1::CardsController < Api::V1::BaseController
  before_filter :require_authentication, :only => :update

  def update
    # Grab the account too
    scroll_account = ScrollAccount.where(:user_id => @user._id, :uid => params[:uid].to_s).first
    unless scroll_account
      return render_error(:no_scroll_found)
    end

    # Figure out what we got to work with
    inventory_cache = {}
    UserInventory.where(:user_id => @user._id).each do |inv|
      inventory_cache[inv.card_id.to_s] = inv
    end

    # Cache cards
    card_map = Rails.cache.fetch("card/map", :expires_in => 15.minutes) do
      cards = {}
      Card.only(:card_id).each do |card|
        cards[card.card_id] = card._id.to_s
      end

      cards
    end

    # Annd sync it all
    collection = MultiJson.load(params[:collection].to_s)
    collection.each do |card_id, data|
      sp_card_id = card_map[card_id.to_i]
      next unless sp_card_id

      new_total, new_trade = data["total"].to_i, data["trade"].to_i
      new_total = 0 if new_total < 0
      new_trade = 0 if new_trade < 0

      inventory = inventory_cache.delete(sp_card_id) || UserInventory.new(:user_id => @user._id, :scroll_account_id => scroll_account._id)
      unless inventory.new_record?
        # Automatically reduce what we want to buy if we gained new cards
        change = (new_total - inventory.quantity)
        if change > 0 and inventory.buy_quant? and inventory.buy_quant > 0
          inventory.buy_quant -= change
          inventory.buy_quant = 0 if inventory.buy_quant < 0
        end

        # Automatically reduce what we want to sell if our tradeable quantity went down
        change = (inventory.trade_quant - new_trade)
        if change > 0 and inventory.sell_quant? and inventory.sell_quant
          inventory.sell_quant -= change
          inventory.sell_quant = 0 if inventory.sell_quant < 0
        end
      end

      inventory.quantity = new_total
      inventory.trade_quant = new_trade
      inventory.deck_quant = 0
      inventory.card_id = sp_card_id
      inventory.save if inventory.changed?
    end

    inventory_cache.each do |card_id, inventory|
      inventory.set(:quantity => 0, :trade_quant => 0)
    end

    render :nothing => true, :status => :no_content
  end

  def index
    unless params[:key] == "!internalt4132941543gWDFRwdf"
      return render_404
    end

    render :json => Card.only(:card_id, :image_id).map {|c| {:card_id => c.card_id, :image_id => c.image_id}}
  end
end