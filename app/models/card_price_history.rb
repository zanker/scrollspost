class CardPriceHistory
  include MongoMapper::Document

  BUY, SELL = 0, 1

  key :flag, Integer

  key :name, String
  key :room, String

  key :price, Integer
  key :quantity, Integer

  key :created_at, Time

  belongs_to :game_version
  belongs_to :card
end