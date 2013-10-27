class LogPriceGraph
  include Sidekiq::Worker
  sidekiq_options :queue => :high, :retry => false

  def perform(type)
    period_key = type == CardPriceGraph::HOURLY ? "h1" : "d1"

    if type == CardPriceGraph::HOURLY
      created_at = Time.now.utc.change(:min => 0)
    else
      created_at = Time.now.utc.change(:hour => 0)
    end

    inserts = []

    Card.only("pricing.#{period_key}").each do |card|
      data = card.pricing[period_key] || {}

      graph = {}
      graph[:card_id] = card._id
      graph[:type] = type
      graph[:suggested] = data["sug"]
      graph[:buy] = data["buy"] && data["buy"]["p95"] || 0
      graph[:buy_units] = data["buy"] && data["buy"]["total"] || 0
      graph[:sell] = data["sell"] && data["sell"]["p95"] || 0
      graph[:sell_units] = data["sell"] && data["sell"]["total"] || 0
      graph[:created_at] = created_at

      inserts << graph
    end

    unless inserts.empty?
      CardPriceGraph.collection.insert(inserts)
    end
  end
end