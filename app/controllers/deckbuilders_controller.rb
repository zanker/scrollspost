class DeckbuildersController < ApplicationController
  def index
    @rules = {}
    PassiveRule.only(:name, :slug).sort(:name.asc).each do |rule|
      @rules[rule._id] = {:name => rule.name, :slug => rule.slug}
    end

    @categories = {}
    Card::CATEGORY_MAP.each do |key, id|
      @categories[id] = {:name => t("categories.#{key}"), :slug => t("categories.#{key}").parameterize}
    end

    @card_list = {}
    if user_signed_in?
      UserInventory.where(:user_id => current_user._id, :quantity.gt => 0).only(:quantity, :card_id).each do |inventory|
        @card_list[inventory.card_id] = inventory.quantity
      end
    end
  end
end