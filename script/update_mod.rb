#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

require "readline"
require "fileutils"

mod = Mod.first
mod ||= Mod.new(:build => 0, :name => "Official-ScrollsPost", :description => "Official ScrollsPost Mod", :downloads => 0)
mod.version_human = Readline.readline("version [#{mod.version_human}]> ", false)
mod.build += 1

# Pull the mod binary down
url = URI("https://raw.github.com/Shadowed/ScrollsPost/master/Binaries/ScrollsPost.mod.dll")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

res = http.request_get(url.request_uri)
unless res.code == "200"
  puts "Error"
  puts res.inspect
  exit
end

hash = Digest::SHA1.hexdigest(res.body)
if mod.hash == hash
  puts "SHA1 hash has not changed (#{mod.hash})"
  exit
end

File.open(mod.file_path, "wb+") do |f|
  f.write(res.body)
end

mod.hash = hash
mod.save

FileUtils.chown("cap-deploy", "cap-deploy", mod.file_path)
Rails.cache.write("mod-exp", Time.now.utc.to_i)
puts "Deployed #{hash} (v#{mod.version_human}, b#{mod.build})"