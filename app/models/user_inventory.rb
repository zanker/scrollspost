class UserInventory
  include MongoMapper::Document

  key :quantity, Integer, :default => 0
  key :trade_quant, Integer, :default => 0
  key :deck_quant, Integer, :default => 0

  key :sell_quant, Integer
  key :sell_price, Integer

  key :buy_quant, Integer
  key :buy_price, Integer

  key :public, Boolean

  timestamps!

  belongs_to :card
  belongs_to :scroll_account
  belongs_to :user
end