class GameStat
  include MongoMapper::Document

  ONLINE, TOTAL_CARDS, TOTAL_GOLD, TOTAL_SOLD = 0, 1, 2, 3

  key :type, Integer
  key :total, Integer
  key :created_at, Time
end