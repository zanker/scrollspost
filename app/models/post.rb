class Post
  include MongoMapper::Document

  key :title, String
  key :slug, String

  key :short_body, String
  key :body, String

  timestamps!

  def self.last_post
    Rails.cache.fetch("news", :expires_in => 30.minutes) { Post.only(:created_at).sort(:created_at.desc).first.created_at.to_s }
  end
end