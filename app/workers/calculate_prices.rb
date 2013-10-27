class CalculatePrices
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  CARD_STATS = "card-stats"

  def perform(period_key, period)
    redis = Redis.current.checkout

    started_at = Time.now.utc
    time_period_start = started_at - period

    # Remove the hash once the dedup period is past
    CardPriceHistory.unset({:created_at.lt => 6.hours.ago.utc, :hash.exists => true}, :hash)

    res = CardPriceHistory.collection.aggregate([
      {"$match" => {:created_at => {"$gte" => time_period_start}}},
      {"$group" => {
        :_id => {"card_id" => "$card_id", "flag" => "$flag"}, "total" => {"$sum" => 1}, "prices" => {"$push" => "$price"}
      }}
    ])

    price_updates, price_stats = {}, {}

    res.each do |stats|
      flag = stats["_id"]["flag"] == CardPriceHistory::SELL ? :sell : :buy

      # Pull out anything that's 0
      prices = stats["prices"].delete_if {|p| p <= 0}

      avg = prices.length > 0 ? (prices.sum.to_f / prices.length).round : 0

      # Figure out what 5% looks like
      top_5 = (prices.length * 0.05).ceil

      # And remove the highest 5% for selling
      if flag == :sell
        prices = prices.sort {|a, b| b <=> a}
      # Strip out the lowest 5% for buying
      else
        prices = prices.sort {|a, b| a <=> b}
      end

      prices.slice!(0, top_5)

      # Calculate percentile
      percentile_95 = prices.length > 0 ? (prices.sum.to_f / prices.length).round : 0

      # Now pull anything out that is excessively outside the bounds
      low_bound, high_bound = percentile_95 * 0.50, percentile_95 * 1.50
      prices = prices.delete_if {|p| p >= high_bound or p <= low_bound}

      # And recalculate the percentile
      percentile_95 = prices.length > 0 ? (prices.sum.to_f / prices.length).round : 0


      to_update = price_updates[stats["_id"]["card_id"]] ||= {:price_updated_at => Time.now.utc}

      to_update["pricing.#{period_key}.#{flag}"] = {"avg" => avg, "p95" => percentile_95, "total" => stats["total"]}

      price_stats[stats["_id"]["card_id"]] ||= {}
      price_stats[stats["_id"]["card_id"]][flag] = percentile_95

      StatTracker.gauge("card.history/#{flag}", stats["total"])
    end

    price_stats.each do |card_id, stats|
      unless stats[:buy] and stats[:sell]
        card = Card.where(:_id => card_id).only("pricing.#{period_key}.buy.p95", "pricing.#{period_key}.sell.p95").first
        stats[:buy] ||= (card.pricing[period_key] && card.pricing[period_key]["buy"] && card.pricing[period_key]["buy"]["p95"] || 0)
        stats[:sell] ||= (card.pricing[period_key] && card.pricing[period_key]["sell"] && card.pricing[period_key]["sell"]["p95"] || 0)
      end

      price = stats[:buy] + stats[:sell]
      total = (stats[:buy] > 0 ? 1 : 0) + (stats[:sell] > 0 ? 1 : 0)
      price_updates[card_id]["pricing.#{period_key}.sug"] = total > 0 ? (price.to_f / total).round : 0
    end

    # Map our id -> scrolls id
    if period_key == "d1"
      card_map = {}
      Card.only(:card_id).each {|c| card_map[c._id] = c.card_id}
    end

    # Push all the buy/sell/percentile suggestions
    price_updates.each do |card_id, to_update|
      if period_key == "d1"
        redis.hset(CARD_STATS, card_map[card_id], "#{to_update["pricing.#{period_key}.sug"]},#{price_stats[card_id][:buy]},#{price_stats[card_id][:sell]}")
      end

      # Grab the last seen date
      newest = CardPriceHistory.where(:card_id => card_id, :created_at.gte => time_period_start).sort(:created_at.desc).only(:created_at).limit(1).first
      to_update[:price_seen_at] = newest.created_at

      Card.set(card_id, to_update)
    end

    Rails.cache.write("card-cache", Time.now.to_i)
    Rails.cache.write("price-#{period_key}-cache", Time.now.utc)

  ensure
    Redis.current.checkin
  end
end