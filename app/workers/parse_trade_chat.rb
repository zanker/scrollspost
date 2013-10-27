class ParseTradeChat
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  TRADE_QUEUE = "trade-msg-queue"
  CARD_LIST = "card-list"
  SELL_REGEX = /(wts|w\st\ss|sell|wtsell|wt\ssell|sale)(ing)?/i
  BUY_REGEX = /(wtb|w\st\sb|wtbuy|wt\sbuy|buy|purchase)(ing)?/i
  UNPARSABLE_LOG = "unparsable-logs"
  # Hard cap on prices
  HARD_PRICE_CAP = 10_000
  # Values for controlling de duping of messages
  DEDUP_TIME_TO = 60 * 60.0

  def perform
    redis = Redis.current.checkout

    # Grab a bunch of logs to parse
    logs = redis.multi do
      redis.lrange(TRADE_QUEUE, 0, 1_000)
      redis.ltrim(TRADE_QUEUE, 1_001, 50_000)
    end.first

    # Nothing to parse yet
    #return if logs.empty?

    card_map, card_names, card_regex = load_card_data(redis)

    # Sort through everything
    log_summary, hash_summary = {}, {}
    logs.each do |log|
      StatTracker.increment("trade.logs.total/count")

      log = MultiJson.load(log)

      # No numbers, so it's pointless to try and pull a price out
      next unless log["msg"] =~ /[0-9]{2,}/

      has_buy, has_sell = log["msg"] =~ BUY_REGEX, log["msg"] =~ SELL_REGEX
      if !has_buy and !has_sell
        redis.lpush(UNPARSABLE_LOG, MultiJson.dump(log))
        StatTracker.increment("trade.logs/unparsable")
        next
      end

      msg = log["msg"]
      # Strip the energy/growth/order/decay tags that some people start a list with
      msg.gsub!(/(energy|growth|order|decay):/i, "")
      # Strip anything that will get in our way
      msg.gsub!(/[^a-zA-Z0-9\*']/, " ")
      # Only allow one space in case they double space names or whatever
      msg.gsub!(/\s{2,}/, " ")
      # Now strip any trailing spaces
      msg.strip!
      # And make it easier to parse
      msg.downcase!

      # Parse message
      msg.gsub(/(#{BUY_REGEX}|#{SELL_REGEX})/, '|SPLIT|\1').split("|SPLIT|").each do |text|
        next if text.blank?
        flag = text =~ BUY_REGEX ? :buy : :sell

        results = text.scan(/([0-9]+[x\*])?\s?(#{card_regex})\s?([0-9]{2,}\s?g[old]?\s?)?([x\*][0-9]+|[0-9]+[x\*])?\s?(([0-9]{2,})\s?g?[old]?)?/)

        # Data!
        active_cards = {}
        results.each do |match|
          quantity = match[0] || match[3]
          quantity = quantity ? quantity.gsub(/[^0-9]/, "").to_i : 1

          card_id = card_map[match[1].strip]
          next unless card_id

          price = match[2] || match[4]
          next unless price

          active_cards[card_id] = true

          price = price.gsub(/[^0-9]/, "").to_i
          next if price >= HARD_PRICE_CAP

          # Used for deduping
          hash = Digest::MD5.hexdigest("#{log["from"]},#{(log["created_at"] / DEDUP_TIME_TO).floor * DEDUP_TIME_TO},#{card_id}")
          next if hash_summary[hash]

          hash_summary[hash] = true

          summary = log_summary[card_id] ||= {:buy => [], :sell => []}
          summary[flag] << [log["from"], Time.at(log["created_at"]), quantity, price, hash, text, log["room"]]
        end

        # Do a pass to try and extract any item names for incrementing popularity numbers
        text.scan(/#{card_regex}/).each do |name|
          card_id = card_map[name.strip]
          next unless card_id
          # Don't increment popularity if we already found it
          next if active_cards[card_id]
          active_cards[card_id] = true

          hash = Digest::MD5.hexdigest("#{log["from"]},#{(log["created_at"] / DEDUP_TIME_TO).floor * DEDUP_TIME_TO},#{card_id}")
          next if hash_summary[hash]

          hash_summary[hash] = true

          summary = log_summary[card_id] ||= {:buy => [], :sell => []}
          summary[flag] << [log["from"], Time.at(log["created_at"]), 1, 0, hash, text, log["room"]]
        end

        # Can't parse it, log it for further study
        if results.empty?
          redis.lpush(UNPARSABLE_LOG, MultiJson.dump(log.merge("frag" => text)))
          StatTracker.increment("trade.logs/unparsable")
        end
      end

      StatTracker.increment("trade.logs/parsed")
    end

    # Trim the unparsable logs to keep the last 5k bad messages
    redis.ltrim(UNPARSABLE_LOG, 0, 5_000)

    # Pull the active hashes that match
    CardPriceHistory.set({:hash.in => hash_summary.keys}, {:created_at => Time.now.utc})
    CardPriceHistory.where(:hash.in => hash_summary.keys).only(:hash).each do |history|
      hash_summary.delete(history.hash)
    end

    # Push everything to the DB
    game_version_id = GameVersion.active_version_id

    inserts = []

    log_summary.each do |card_id, summary|
      summary.each do |flag, logs|
        flag = flag == :buy ? CardPriceHistory::BUY : CardPriceHistory::SELL

        logs.each do |log|
          # Push to live redis log
          line = "#{Time.now.utc.to_i},#{log[3]},#{log[0]},#{log[6]}"
          dup_key = "cdup:#{card_id}:#{flag}:#{log[0]}:#{log[3]}"

          # Remove the duplicate entry
          unless redis.ext_set(dup_key, line, :ex => 5.minutes, :nx => true) == "OK"
            dup_line = redis.get(dup_key)
            redis.lrem("clogs:#{card_id}:#{flag}", 1, dup_line)
            redis.lrem("clogs", 1, "#{flag},#{card_id},#{dup_line}")

            redis.set(dup_key, line)
          end

          redis.lpush("clogs:#{card_id}:#{flag}", line)
          redis.lpush("clogs", "#{flag},#{card_id},#{line}")

          unless hash_summary[log[4]]
            StatTracker.increment("trade.parsed/dup")
            next
          end

          # And make sure that anything else is considered a dup
          hash_summary.delete(log[4])

          inserts << {:flag => flag, :card_id => card_id, :quantity => log[2], :price => log[3], :game_version_id => game_version_id, :name => log[0], :created_at => log[1], :hash => log[4], :raw_log => log[5], :room => log[6]}
        end

        # Trim it down
        redis.ltrim("clogs:#{card_id}:#{flag}", 0, 15)
        redis.expire("clogs:#{card_id}:#{flag}", 12.hours)
      end
    end

    # Trim down the global trade log
    redis.ltrim("clogs", 0, 100)

    unless inserts.empty?
      CardPriceHistory.collection.insert(inserts)
    end

    StatTracker.gauge("trade.parsed/logged", inserts.length)

  ensure
    Redis.current.checkin
  end

  # Card data formatted for our quick use
  def load_card_data(redis)
    Rails.cache.fetch("card-regex", :expires_in => 30.minutes) do
      SyncGameData.new.perform

      card_map = {}
      card_names = {}

      # Tokenize for searching
      regex_strips = [
        # Missing spaces
        [/\s/, ""],
        # Non alphabetical/spaces
        [/[^a-zA-Z0-9\s]/, ""],
        # Incendiary over Incendiaries
        [/ies$/, ""],
        # Efficency over Efficiency
        [/ie/, "e"],
        # Scattergun over Scattergunner
        [/ner$/, ""],
        # New Order over New Orders
        [/s$/, ""],
        # Sister of Fox over Sister of the Fox
        [/ the /, " "],
        # Potion of Resistence over Potion of Resistance
        [/a/, "e"],
        # Waking Stones over Waking Stones
        [/$/, "s"]
      ]

      card_regex = []
      Card.only(:name).each do |card|
        name = card_names[card._id] = card.name
        name = name.downcase

        # Just the name itself
        card_regex << name
        card_map[name] = card._id

        # TEMP
        card_map[card._id] = card.name

        # Do the first pass strips to get typos/etc
        regex_strips.each do |find, replace|
          parsed = name.gsub(find, replace)
          card_regex << parsed
          card_map[parsed] = card._id

          # Now combine it with every other strip to be doubly sure
          regex_strips.each do |find_sub, replace_sub|
            next if find_sub == find

            sub_parsed = parsed.gsub(find_sub, replace_sub)
            card_regex << sub_parsed

            card_map[sub_parsed] = card._id
          end
        end
      end

      card_regex = card_regex.uniq.join("|")

      [card_map, card_names, card_regex]
    end
  end
end