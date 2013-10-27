#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

require "rmagick"
# Grab a list of all the image ids in the game
response = Net::HTTP.get(URI.parse("http://api.scrollspost.com/v1/cards?key=!internalt4132941543gWDFRwdf"))

image_map = {}
MultiJson.load(response).each do |card|
  image_map[card["image_id"]] = true
end

# Now grab what we have cached
Dir[Rails.root.join("app", "assets", "images", "cards", "original-*.png")].each do |path|
  name = File.basename(path, ".png")
  id = name.split("-", 2)[1].to_i
  next unless id > 0

  image_map.delete(id)
end

# And figure out what we're missing
image_map.each_key do |image_id|
  puts

  # Pull the original asset
  puts "Loading image for #{image_id}"
  path = Rails.root.join("app", "assets", "images", "cards", "original-#{image_id}.png")

  response = Net::HTTP.get(URI.parse("http://54.208.22.193:8082/img/#{image_id}"))

  File.open(path, "wb+") do |f|
    f.write(response)
  end

  # Do the size generation
  puts "Generating different sizes"

  image = Magick::Image.read(path).first
  [["large", "200x150"], ["medium", "153x115"], ["small", "73x55"], ["tiny", "40x30"]].each do |type, size|
    puts "Generating #{type} (#{size})"

    image.change_geometry!(size) do |cols, rows, img|
      new = image.resize(cols, rows)
      new.write(Rails.root.join("app", "assets", "images", "cards", "#{type}-#{image_id}.png"))
    end
  end

  puts "Loaded #{image_id}"
end

# Crushing images
files = {}
["original", "large", "medium", "small", "tiny"].each do |type|
  image_map.each_key do |image_id|
    path = Rails.root.join("app", "assets", "images", "cards", "#{type}-#{image_id}.png")
    size = File.size(path)

    files[path] = size
  end
end

puts
puts "Crushing #{files.length} images"

`echo '#{files.keys.join("\n")}' | /usr/local/imageoptim/imageOptim -q 2>&1`

# Now check how much we saved
files.each do |path, size|
  new_size = File.size(path)
  puts "#{File.basename(path)}, was #{size}, now #{new_size}, saved #{size - new_size} (#{((1 - (new_size.to_f / size)).round * 100).round(4)}%)"
end


puts
puts "Done"