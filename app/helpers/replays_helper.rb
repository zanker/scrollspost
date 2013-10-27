module ReplaysHelper
  def summarize_cards(records)
    cards = {}

    records.each do |record|
      next unless record["t"] == Replay::CARD_PLAYED

      cards[record["cid"]] ||= 0
      cards[record["cid"]] += 1
    end

    list = []
    cards.each {|k, v| list << {:card_id => k, :played => v}}

    list.sort {|a, b| b[:played] <=> a[:played]}
  end

  def deck_summary(replay)
    data = {}

    Replay::SIDE_MAP.each_key do |side|
      data[side] = {}
      replay["#{side}_cards"].each do |id, quantity|
        data[side][id] = quantity
      end
    end

    data
  end

  def build_damage_graph(replay, side)
    resource_series, damage_series, cards = {}, {}, {}

    # Compile it into rounds for summarization purposes
    rounds, resources_used = {}, {}
    replay["#{side}_rounds"].each do |record|
      rounds[(record["rnd"].to_f / 2).round] ||= []
      rounds[(record["rnd"].to_f / 2).round] << record

      if record["t"] == Replay::STATE
        record["resources"].each_key do |type|
          resources_used[type] = true
        end
      end
    end

    # Now off we go
    first_card_round = nil
    rounds.each do |round, records|
      current_type = nil
      resource_summary, damage_summary = nil, 0

      records.each_index do |i|
        record = records[i]

        type_was = current_type
        if record["t"] == Replay::CARD_PLAYED
          first_card_round ||= round

          cards[round] ||= []
          cards[round] << content_tag(:li, "#{image_tag("cards/tiny-#{@cards[record["cid"]].image_id}.png", :class => "cards size-tiny")}#{content_tag(:div, @cards[record["cid"]].name, :class => "name rarity-#{@cards[record["cid"]].rarity}")}".html_safe)
        end

        if record["t"] == Replay::STATE
          unless record["resources"].empty?
            current_type = :resource
            resource_summary = record["resources"]
          end

        elsif ( record["t"] == Replay::IDOL_DMG_DONE or record["t"] == Replay::UNIT_DMG_DONE ) and record["diff"] != 0
          current_type = :damage

          damage_summary += record["diff"].abs
          # Remove overkill
          if record["hp"] < 0
            damage_summary += record["hp"]
          end
        end

        # Type changed
        next_type = records[i + 1] ? records[i + 1]["t"] : nil
        type_was = current_type unless next_type

        if ( !next_type and type_was ) or ( type_was == :resource and ( next_type == Replay::IDOL_DMG_DONE or next_type == Replay::UNIT_DMG_DONE ) ) or ( type_was == :damage and next_type == Replay::STATE )
          # Push the damage onto the list
          if type_was == :damage
            damage_series[round] ||= 0
            damage_series[round] += damage_summary

            damage_summary = 0

          elsif type_was == :resource
            resource_summary.each do |type, total|
              resource_series[type] ||= {}
              resource_series[type][round] = total
            end

            resource_summary = nil
          end

          # Type change so increment the point to space
          current_type = nil
        end

      end

      # Add filler points if we had no data
      damage_series[round] ||= 0
    end

    damage_series = damage_series.to_a
    resource_series.each do |type, series|
      resource_series[type] = series.to_a
    end

    {"resource" => resource_series, "damage" => damage_series, "cards" => cards, "first_card_round" => first_card_round}.to_json
  end
end