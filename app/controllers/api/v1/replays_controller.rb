class Api::V1::ReplaysController < Api::V1::BaseController
  def create
    if params[:replay].blank? or !params[:replay].respond_to?(:original_filename)
      return render_error(:no_upload)
    end

    ext = File.extname(params[:replay].original_filename)
    replay_type = ext == ".spr" && :scrollspost || ext == ".sgr" && :scrollsguide || nil
    unless replay_type
      return render_error(:not_replay)
    end

    replay = Replay.new
    last_card, current_turn = nil, nil
    tile_to_card, unit_to_card_id, cards_seen = {}, {}, {}

    replay_conversion = []
    replay_contents = File.read(params[:replay].path)
    replay_contents.split("\n").each do |line|
      line.strip!
      next if line.blank?

      if replay_type == :scrollspost
        if line =~ /^metadata/

          metadata = MultiJson.load(line.split("|", 2).last)

          version = GameVersion.where("$or" => [{:version => metadata["version"].to_s}, {:internal_version => metadata["version"].to_s}]).only(:_id).first
          replay.game_version_id = version._id if version

          replay.played_at = Time.at(metadata["played-at"].to_i).utc
          next
        end

        line = line.split("|", 3).last
      end

      # Parsing game events
      data = MultiJson.load(line)

      # ScrollsGuide, need to start rewriting it into our format
      if replay_type == :scrollsguide
        if data["msg"] == "GetFriends" or data["msg"] == "GetFriendRequests" or data["msg"] == "GetBlockedPersons"
          next
        end

        data["msg"] == "NewEffects" ? 1.2 : 0.3
        elapsed = case data["msg"]
          when "NewEffects" then 1.2
          when "Ping" then 0
          when "GameChatMessage" then 0.1
          when "CardInfo" then 0.3
          else 0.2
        end

        replay_conversion << "elapsed|#{elapsed}|#{line}"
      end

      # Pull game version
      if data["msg"] == "ServerInfo"
        version = GameVersion.where("$or" => [{:version => data["version"].to_s}, {:internal_version => data["version"].to_s}]).only(:_id).first
        replay.game_version_id = version._id if version

      # Base game info
      elsif data["msg"] == "GameInfo"
        replay.perspective = data["color"] == "white" ? Replay::WHITE : Replay::BLACK
        replay.game_id = data["gameId"].to_i
        replay.game_timer = data["roundTimerSeconds"].to_i
        replay.game_type = Replay::GAME_TYPE_MAP[data["gameType"]]

        replay.white_name = data["white"]
        replay.white_id = data["whiteAvatar"]["profileId"]

        replay.black_name = data["black"]
        replay.black_id = data["blackAvatar"]["profileId"]

        unless replay.multiplayer?
          other_side = data["color"] == "white" ? "black" : "white"
          replay.difficulty = Replay::DIFFICULTY_MAP[data["#{other_side}Avatar"]["profileId"]]
        end

      # Log ratings
      elsif data["msg"] == "RatingUpdate"
        replay.white_rating = data["whiteNewRating"].to_i
        replay.white_rate_chg = data["whiteChange"].to_i
        replay.black_rating = data["blackNewRating"].to_i
        replay.black_rate_chg = data["blackChange"].to_i

      # Grab when it was played
      elsif data["msg"] == "Ping" and !replay.played_at?
        replay.played_at = Time.at(data["time"].to_i / 1000).utc

      # Loading game state (Trials mostly, probably reconnects too)
      elsif data["msg"] == "GameState"
        Replay::SIDE_MAP.each_key do |side|
          state = data["#{side}GameState"]

          tile_to_card[side] ||= {}
          state["board"]["tiles"].each do |tile|
            tile_to_card[side][tile["typeId"]] = tile["position"]
          end
        end

      # Effects can be everything from a game ending to a turn
      elsif data["msg"] == "NewEffects"
        data["effects"].each do |effect|
          # Game over
          if effect["EndGame"]
            game = effect["EndGame"]

            replay.winner = game["winner"] == "white" ? Replay::WHITE : Replay::BLACK
            replay.game_length = 0

            Replay::SIDE_MAP.each_key do |side|
              # Log game stats
              stats = game["#{side}Stats"]
              parsed = {"udmg" => stats["unitDamage"].to_i, "idmg" => stats["idolDamage"].to_i, "uplay" => stats["unitsPlayed"].to_i, "splay" => stats["spellsPlayed"].to_i, "eplay" => stats["enchantmentsPlayed"].to_i, "drawn" => stats["scrollsDrawn"].to_i, "hdmg" => stats["mostDamageUnit"].to_i, "ikill" => stats["idolsDestroyed"].to_i}

              unit_id = stats["mostDamageUnitId"].to_i
              if unit_id > 0 and unit_to_card_id[side] and unit_to_card_id[side][unit_id]
                parsed["hdmgID"] = unit_to_card_id[side][unit_id]
              end

              replay.send("#{side}_time=", stats["totalMs"] > 0 ? (stats["totalMs"].to_i / 1000) : 0)
              replay.send("#{side}_stats=", parsed)

              # Log gold
              stats = game["#{side}GoldReward"]

              parsed = {"match" => stats["matchReward"].to_i, "compl" => stats["matchCompletionReward"].to_i, "idols" => stats["idolsDestroyedReward"].to_i, "total" => stats["totalReward"].to_i}
              replay.send("#{side}_gold=", parsed)

              # Total game time
              replay.game_length += replay.send("#{side}_time")
            end

          # Surrender
          elsif effect["SurrenderEffect"]
            replay.surrender = effect["SurrenderEffect"]["color"] == "white" ? Replay::WHITE : Replay::BLACK

          # New turn
          elsif effect["TurnBegin"]
            replay.game_rounds = effect["TurnBegin"]["turn"].to_i
            current_turn = effect["TurnBegin"]["color"] == "white" ? Replay::WHITE : Replay::BLACK

          # Unit on board
          elsif effect["SummonUnit"]
            unit = effect["SummonUnit"]

            side = unit["target"]["color"] == "white" ? "white" : "black"
            if unit["card"]
              card_id, user_card_id = unit["card"]["typeId"], unit["card"]["id"]
            else
              user_card_id = card_id = unit["unit"]["cardTypeId"].to_i
            end

            replay.send("#{side}_rounds") << {"rnd" => replay.game_rounds, "cid" => card_id, "t" => Replay::UNIT_SUMMONED}

            tile_to_card[side] ||= {}
            tile_to_card[side][unit["target"]["position"]] = card_id
            cards_seen[side][user_card_id] = card_id

          # Card for cards or resources
          elsif effect["CardSacrificed"]
            sac = effect["CardSacrificed"]
            side = sac["color"] == "white" ? "white" : "black"
            side_id = side == "white" ? Replay::WHITE : Replay::BLACK

            # Sacrificed for resources
            if sac["resource"]
              type = Replay::SAC_RESOURCES
              replay.send("#{side}_sac_res=", replay.send("#{side}_sac_res") + 1)

            # Otherwise cards
            else
              type = Replay::SAC_CARDS
              replay.send("#{side}_sac_cards=", replay.send("#{side}_sac_cards") + 1)
            end

            event = {"rnd" => replay.game_rounds, "t" => type, "tc" => current_turn}
            if side_id == replay.perspective
              event["cid"] = last_card["typeId"]

              cards_seen[side] ||= {}
              cards_seen[side][last_card["id"]] = last_card["typeId"]
            end

            replay.send("#{side}_rounds") << event

          # Resource #s
          elsif effect["ResourcesUpdate"]
            update = effect["ResourcesUpdate"]

            Replay::SIDE_MAP.each_key do |side|
              event = {"resources" => {}}
              event["hand"] = update["#{side}Assets"]["handSize"].to_i

              update["#{side}Assets"]["outputResources"].each do |type, total|
                event["resources"][type.downcase] = total.to_i if total.to_i > 0
              end

              rounds = replay.send("#{side}_rounds")

              last_update = rounds.select {|r| r["t"] == Replay::STATE}.last
              # No change on anything, don't log
              if last_update and last_update["resources"] == event["resources"] and last_update["hand"] == event["hand"]
                next
              end

              rounds << {"rnd" => replay.game_rounds, "t" => Replay::STATE, "tc" => current_turn}.merge(event)
            end

          # Idol HP
          elsif effect["IdolUpdate"]
            update = effect["IdolUpdate"]
            side = update["idol"]["color"] == "white" ? "black" : "white"
            side_id = side == "white" ? Replay::WHITE : Replay::BLACK

            rounds = replay.send("#{side}_rounds")

            last_idol = rounds.select {|r| r["t"] == Replay::IDOL_DMG_DONE and r["pos"] == update["idol"]["position"]}.last

            diff = 0
            if last_idol
              diff = update["idol"]["hp"].to_i - last_idol["hp"]
            end

            update["idol"]["hp"] += diff
            rounds << {"rnd" => replay.game_rounds, "t" => Replay::IDOL_DMG_DONE, "hp" => update["idol"]["hp"].to_i, "pos" => update["idol"]["position"].to_i, "diff" => diff}

          # Unit damage
          elsif effect["DamageUnit"]
            unit = effect["DamageUnit"]
            side = unit["targetTile"]["color"] == "white" ? "white" : "black"
            other_side = unit["targetTile"]["color"] == "white" ? "black" : "white"

            rounds = replay.send("#{other_side}_rounds")

            event = {"rnd" => replay.game_rounds, "t" => Replay::UNIT_DMG_DONE, "diff" => unit["amount"].to_i, "hp" => unit["hp"].to_i}
            event["cid"] = tile_to_card[side][unit["targetTile"]["position"]]
            event["kill"] = true if unit["kill"]

            rounds << event

          # Card played (Quake, Creatures, etc)
          elsif effect["CardPlayed"]
            played = effect["CardPlayed"]
            side = played["color"] == "white" ? "white" : "black"

            replay.send("#{side}_rounds") << {"rnd" => replay.game_rounds, "t" => Replay::CARD_PLAYED, "cid" => played["card"]["typeId"].to_i}

            unit_to_card_id[side] ||= {}
            unit_to_card_id[side][played["card"]["id"]] = played["card"]["typeId"]

            cards_seen[side] ||= {}
            cards_seen[side][played["card"]["id"]] = played["card"]["typeId"]

          # For keeping track of tiles -> cards
          elsif effect["MoveUnit"]
            unit = effect["MoveUnit"]
            side = unit["from"]["color"] == "white" ? "white" : "black"

            tile_to_card[side][unit["to"]["position"]] = tile_to_card[side].delete(unit["from"]["position"])

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

    # Do basic sanity checks
    if !replay.game_version_id?
      return render_error(:invalid_version)
    elsif !replay.white_rounds? or !replay.black_rounds?
      return render_error(:no_turns)
    end

    # Figure out resources used and order it by #
    replay.player_ids = []
    Replay::SIDE_MAP.each_key do |side|
      resources = {}

      replay.send("#{side}_rounds").each do |round|
        if round["t"] == Replay::STATE
          round["resources"].each do |type, total|
            if !resources[type] || resources[type] < total
              resources[type] = total
            end
          end
        end
      end

      ordered = resources.keys
      ordered.sort_by {|a| resources[a]}

      replay.send("#{side}_resources=", ordered)
      replay.send("#{side}_res_totals=", resources)
      replay.player_ids << replay.send("#{side}_id")
    end

    # Cache cards sene
    cards_seen.each do |side, cards|
      compiled = {}
      cards.each_value do |card_id|
        compiled[card_id] ||= 0
        compiled[card_id] += 1 if compiled[card_id] < 3
      end

      replay.send("#{side}_cards=", compiled.to_a)
    end

    # Don't allow another replay with the same Game ID/Perspective to be uploaded
    exist_replay = Replay.where(:game_id => replay.game_id, :perspective => replay.perspective).only(:game_id, :perspective, :white_name, :black_name).first
    if exist_replay
      return render_response(:url => show_replay_url(exist_replay.game_id, exist_replay.perspective, :name1 => exist_replay.white_name.parameterize, :name2 => exist_replay.black_name.parameterize))
    end

    if !replay.played_at? || replay.played_at > Time.now.utc
      replay.played_at = Time.now.utc
    end

    if replay.game_rounds == 1
      return render_error(:game_too_short)
    end

    replay.game_resources = (replay.white_resources + replay.black_resources).uniq
    replay.save

    # Move the replay over
    if replay_type == :scrollspost
      require "fileutils"
      FileUtils.move(params[:replay].path, replay.file_path)
    # Otherwise finish rewriting and store the converted copy
    else
      metadata = {"white-id" => replay.white_id, "white-name" => replay.white_name, "black-name" => replay.black_name, "deck" => "Unknown", "black-id" => replay.black_id, "perspective" => replay.perspective == Replay::WHITE ? "white" : "black", "version" => GameVersion.id_to_version(replay.game_version_id), "played-at" => replay.played_at.to_i, "winner" => replay.winner == Replay::WHITE ? "white" : "black"}
      replay_conversion.insert(0, "metadata|#{metadata.to_json}")
      replay_contents = replay_conversion.join("\n")

      File.unlink(params[:replay].path) rescue nil
      File.open(replay.file_path, "w+") {|f| f.write(replay_contents)}
    end

    # Store the compressed form
    File.open("#{replay.file_path}.gz", "wb+") do |f|
      f.write(ActiveSupport::Gzip.compress(replay_contents))
    end

    render_response(:url => show_replay_url(replay.game_id, replay.perspective, :name1 => replay.white_name.parameterize, :name2 => replay.black_name.parameterize))
  end
end