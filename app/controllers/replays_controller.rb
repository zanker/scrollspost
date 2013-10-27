class ReplaysController < ApplicationController
  GAME_TYPES = {"mp-unranked" => Replay::MP_UNRANKED, "mp-ranked" => Replay::MP_RANKED, "mp-quick" => Replay::MP_QUICK, "sp-quick" => Replay::SP_QUICK, "sp-trial" => Replay::SP_TRIAL}
  SORT_KEYS = {"played" => :played_at}

  def download
    replay = Replay.where(:game_id => params[:game_id].to_i, :perspective => params[:perspective].to_i).only(:game_id, :perspective).first
    return render_404 unless replay

    replay.increment(:downloads => 1)

    send_file(replay.file_path)
  end

  def show
    unless params[:page_type].blank? or params[:page_type] == "damage"
      return render_404
    end

    return unless stale?(:etag => "#{params[:game_id]}/#{params[:perspective]}/#{DEPLOY_ID}/#{params[:page_type]}", :public => true)

    cache_page_by_hash("replay/#{params[:game_id]}/#{params[:perspective]}/#{params[:page_type]}/#{DEPLOY_ID}", 2.hours) do
      @replay = Replay.where(:game_id => params[:game_id].to_i, :perspective => params[:perspective].to_i).first
      return render_404 unless @replay

      @cards = {}
      Card.all.each do |card|
        @cards[card.card_id] = card
      end
    end
  end

  def index
    @filters = {:resources => {}}

    @replays = Replay.only(:game_resources, :game_id, :game_type, :game_length, :difficulty, :perspective, :white_rating, :black_rating, :white_id, :black_id, :white_name, :black_name, :played_at, :created_at, :white_resources, :black_resources)
    if SORT_KEYS[params[:sort_by]] and ( params[:sort_mode] == "asc" || params[:sort_mode] == "desc" )
      if params[:sort_by] == "played"
        @replays = @replays.sort(:created_at.send(params[:sort_mode]))
      else
        @replays = @replays.sort(SORT_KEYS[params[:sort_by]].send(params[:sort_mode]), :created_at.desc)
      end
    else
      @replays = @replays.sort(:created_at.desc)
      params[:sort_by], params[:sort_mode] = "played", "desc"
    end

    # Resources
    if params[:resources] != "all"
      params[:resources].split("-").each do |resource|
        if Card::RESOURCE_MAP[resource]
          @filters[:resources][resource] = true
        end
      end

      unless @filters[:resources].empty?
        @replays = @replays.where(:game_resources => @filters[:resources].keys)
      end
    else
      Card::RESOURCE_MAP.each_key {|k| @filters[:resources][k] = true}
    end

    # Game version
    if !params[:version].blank? and params[:version] != "all"
      version_id = GameVersion.version_to_id(params[:version].gsub("-", "."))
      if version_id
        @filters[:version_id] = BSON::ObjectId(version_id)
        @replays = @replays.where(:game_version_id => @filters[:version_id])
      end
    end

    # Rating
    if !params[:min_rating].blank? and !params[:max_rating].blank?
      # Force ranked filtering if rating is set
      params[:type] = "mp-ranked"

      min, max = params[:min_rating].to_i, max = params[:max_rating].to_i
      @replays = @replays.where("$or" => [{:white_rating.gte => min, :white_rating.lte => max}, {:black_rating.gte => min, :black_rating.lte => max}])
    end

    # Game type
    if GAME_TYPES[params[:type]]
      @filters[:type] = GAME_TYPES[params[:type]]
      @replays = @replays.where(:game_type => GAME_TYPES[params[:type]])
    end

    # Player search
    unless params[:player_id].blank?
      id = params[:player_id].to_s.to_i(36).to_s(18)
      unless id.blank?
        # Leading 0s are stripped during the conversion, need to restore themFixed
        id = "0#{id}" if id.length == 31

        @replays = @replays.where(:player_ids => id)
      end
    end

    # Pagination
    @replays = @replays.limit(CONFIG[:limits][:replays])
    if params[:page].to_i > 0
      @replays = @replays.skip((params[:page].to_i - 1) * CONFIG[:limits][:replays])
    end
  end
end