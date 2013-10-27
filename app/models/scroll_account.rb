class ScrollAccount
  include MongoMapper::Document

  key :name, String
  key :channel, String
  key :steam_name, String
  key :haggle, Boolean
  key :uid, String
  key :scroll_id, String
  key :rating, Integer
  key :public, Boolean
  key :note, String

  timestamps!

  belongs_to :user

  validates_length_of :channel, :minimum => 1, :maximum => 20, :allow_nil => true
  validates_length_of :steam_name, :minimum => 1, :maximum => 50, :allow_nil => true
  validates_length_of :note, :minimum => 1, :maximum => 255, :allow_nil => true
end