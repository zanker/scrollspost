class Mod
  include MongoMapper::Document

  key :name, String
  key :description, String
  key :build, Integer
  key :version_human, String
  key :downloads, Integer
  key :hash, String

  timestamps!

  def file_path
    if Rails.env.production?
      "/var/www/vhosts/scrollspost/current/public/system/scrollspost/ScrollsPost.mod.dll"
    else
      Rails.root.join("public", "system", "scrollspost", "ScrollsPost.mod.dll")
    end
  end
end