class CacheStoreTotals
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  def perform
    cards = {}

    [:sell, :buy].each do |key|
      res = UserInventory.collection.aggregate([
        {"$match" => {:public => true, "#{key}_quant" => {"$gt" => 0}}},
        {"$group" => {:_id => {"card_id" => "$card_id"}, "total" => {"$sum" => "$#{key}_quant"}, "min" => {"$min" => "$#{key}_price"}, "avg" => {"$avg" => "$#{key}_price"}}},
      ])

      res.each do |stats|
        card = cards[stats.delete("_id")["card_id"]] ||= {}
        card[key] = stats
      end
    end

    cards.each do |card_id, stats|
      stats[:buy] ||= {"total" => 0, "min" => 0}
      stats[:sell] ||= {"total" => 0, "min" => 0}
      Card.set(card_id, :store_updated_at => Time.now.utc, "store.buy" => {"total" => stats[:buy]["total"].to_i, "min" => stats[:buy]["min"].to_i}, "store.sell" => {"total" => stats[:sell]["total"].to_i, "min" => stats[:sell]["min"].to_i})
    end

    Rails.cache.write("store-cache", Time.now.utc.to_i.to_s)
  end
end