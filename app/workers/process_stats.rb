class ProcessStats
  include Sidekiq::Worker
  sidekiq_options :queue => :high, :retry => false

  STATS_QUEUE = "stats-queue"
  TYPE_MAP = {"online" => GameStat::ONLINE, "totalcards" => GameStat::TOTAL_CARDS, "totalsold" => GameStat::TOTAL_SOLD, "totalgold" => GameStat::TOTAL_GOLD}

  def perform
    Redis.current.with do |r|
      while ( stat = r.lpop(STATS_QUEUE) ) != nil
        type, total, time = stat.split(",", 3)
        GameStat.create!(:type => TYPE_MAP[type], :total => total.to_i, :created_at => Time.at(time.to_i).utc)
      end
    end

    Rails.cache.write("stat-cache", Time.now.utc.to_i.to_s)
  end
end