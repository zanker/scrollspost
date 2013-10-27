require File.expand_path("../../config/application", __FILE__)
Rails.application.require_environment!

Replay.all.each do |replay|
  puts "Parsing #{replay._id}, #{replay.game_id}, #{replay.perspective}"

  cards_seen = {}
  last_card = nil

  File.read(replay.file_path).split("\n").each do |line|
    line.strip!
    next if line.blank?
    next if line =~ /^metadata/

    line = line.split("|", 3).last

    # Parsing game events
    data = MultiJson.load(line)

    if data["msg"] == "NewEffects"
      data["effects"].each do |effect|
        # Card for cards or resources
        if effect["CardSacrificed"]
          sac = effect["CardSacrificed"]
          side = sac["color"] == "white" ? "white" : "black"
          side_id = side == "white" ? Replay::WHITE : Replay::BLACK

          if side_id == replay.perspective and last_card
            cards_seen[side] ||= {}
            cards_seen[side][last_card["id"]] = last_card["typeId"]
          end

        # Card played (Quake, Creatures, etc)
        elsif effect["CardPlayed"]
          played = effect["CardPlayed"]
          side = played["color"] == "white" ? "white" : "black"

          cards_seen[side] ||= {}
          cards_seen[side][played["card"]["id"]] = played["card"]["typeId"]

        elsif effect["SummonUnit"]
          unit = effect["SummonUnit"]

          side = unit["target"]["color"] == "white" ? "white" : "black"
          if unit["card"]
            card_id = unit["card"]["id"]
          else
            card_id = unit["unit"]["cardTypeId"].to_i
          end

          cards_seen[side] ||= {}
          cards_seen[side][card_id] = card_id

        # Hand
        elsif effect["HandUpdate"]
          side = effect["HandUpdate"]["profileId"] == replay.white_id ? "white" : "black"
          cards_seen[side] ||= {}

          effect["HandUpdate"]["cards"].each do |card|
            cards_seen[side][card["id"]] = card["typeId"]
          end
        end
      end

    # User clicked on a card
    elsif data["msg"] == "CardInfo"
      last_card = data["card"]
    end
  end

  puts "SEEN: #{cards_seen.inspect}"
  cards_seen.each do |side, cards|
    compiled = {}
    cards.each_value do |card_id|
      compiled[card_id] ||= 0
      compiled[card_id] += 1 if compiled[card_id] < 3
    end

    replay.set("#{side}_cards" => compiled.to_a)
  end
end