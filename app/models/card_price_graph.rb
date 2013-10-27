class CardPriceGraph
  include MongoMapper::Document

  HOURLY, DAILY = 0, 1

  key :type, Integer

  key :suggested, Integer

  key :buy, Integer
  key :buy_units, Integer

  key :sell, Integer
  key :sell_units, Integer

  key :created_at, Time

  belongs_to :card
end