#!/usr/bin/env ruby
require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

CardPriceGraph.delete_all

[[CardPriceGraph::DAILY, 24.hours], [CardPriceGraph::HOURLY, 1.hour]].each do |graph_type, period|
  puts "Updating for #{period} time period"

  earliest = CardPriceHistory.sort(:created_at.asc).first.created_at
  earliest = earliest.change(:hour => 0)

  card_last_stats = {}

  while true do
    puts "TIME: #{earliest}"

    unless CardPriceHistory.where(:created_at.gte => earliest).exists?
      puts "Ran out of card data"
      break
    end

    res = CardPriceHistory.collection.aggregate([
      {"$match" => {:created_at => {"$gte" => earliest, "$lt" => earliest + period}}},
      {"$group" => {
        :_id => {"card_id" => "$card_id", "flag" => "$flag"}, "total" => {"$sum" => 1}, "prices" => {"$push" => "$price"}
      }}
    ])

    period_data = {}

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

      data = period_data[stats["_id"]["card_id"]] ||= {}
      data[flag] = {"p95" => percentile_95, "total" => stats["total"]}

      data = card_last_stats[stats["_id"]["card_id"]] ||= {}
      data[flag] = {"total" => stats["total"]}
      if percentile_95 > 0
        data[flag]["p95"] = percentile_95
      end
    end

    inserts = []
    period_data.each do |card_id, stats|
      stats[:buy] ||= card_last_stats[card_id][:buy]
      stats[:sell] ||= card_last_stats[card_id][:sell]

      graph = {}
      graph[:type] = graph_type
      graph[:card_id] = card_id
      graph[:buy] = 0
      graph[:buy_units] = 0
      graph[:sell] = 0
      graph[:sell_units] = 0

      if stats[:buy]
        graph[:buy] = stats[:buy]["p95"]
        graph[:buy_units] = stats[:buy]["total"]
      end

      if stats[:sell]
        graph[:sell] = stats[:sell]["p95"]
        graph[:sell_units] = stats[:sell]["total"]
      end

      graph[:created_at] = earliest
      inserts << graph
    end

    unless inserts.empty?
      CardPriceGraph.collection.insert(inserts)
    end

    earliest += period
  end
end

CardPriceGraph.collection.find({:suggested => {"$exists" => false}}, {:fields => {:buy => true, :sell => true}, :timeout => false}) do |cursor|
  cursor.each do |graph|
    total = (graph["buy"].to_i > 0 ? 1 : 0) + (graph["sell"].to_i > 0 ? 1 : 0)
    suggested = graph["buy"].to_i + graph["sell"].to_i
    suggested = suggested > 0 ? (suggested.to_f / total).round : 0

    CardPriceGraph.set(graph["_id"], :suggested => suggested)

    puts "Set suggested #{graph["_id"]}, #{suggested}"
  end
end

[:buy, :buy_units, :sell, :sell_units].each do |key|
  CardPriceGraph.set({key => {"$exists" => false}}, key => 0)
  puts "Defaulted key #{key}"
end