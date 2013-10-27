class PassiveRule
  include MongoMapper::Document

  key :name, String
  key :slug, String
  key :desc, String

  timestamps!
end