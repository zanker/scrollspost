class Ability
  include MongoMapper::Document

  key :ability_id, String
  key :name, String
  key :desc, String

  key :cost_order, Integer
  key :cost_decay, Integer
  key :cost_growth, Integer
  key :cost_energy, Integer

  timestamps!
end