Dir[Rails.root.join("app", "javascripts", "*.js")].each do |path|
  BSON_CACHE[File.basename(path, ".js").to_sym] = BSON::Code.new(File.read(path))
end

Dir[Rails.root.join("app", "javascripts", "*.js.erb")].each do |path|
  BSON_CACHE[File.basename(path, ".js.erb").to_sym] = BSON::Code.new(ERB.new(File.read(path)).result)
end