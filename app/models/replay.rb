class Replay
  include MongoMapper::Document

  WHITE, BLACK = 0, 1
  SIDE_MAP = {"white" => WHITE, "black" => BLACK}

  SAC_CARDS, SAC_RESOURCES, UNIT_SUMMONED, STATE, IDOL_DMG_DONE, UNIT_DMG_DONE, CARD_PLAYED = 0, 1, 2, 3, 4, 5, 6

  EASY, MEDIUM, HARD = 0
  DIFFICULTY_MAP = {"RobotEasy" => EASY, "RobotMedium" => MEDIUM, "RobotHard" => HARD}
  ROBOT_IDS = {"RobotEasy" => true, "RobotMedium" => true, "RobotHard" => true, "RobotTower" => true}

  MP_RANKED, MP_UNRANKED, MP_QUICK, SP_TRIAL, SP_QUICK, SP_TUTORIAL = 0, 1, 2, 3, 4, 5
  GAME_TYPE_MAP = {"MP_UNRANKED" => MP_UNRANKED, "MP_RANKED" => MP_RANKED, "MP_QUICKMATCH" => MP_QUICK, "SP_QUICKMATCH" => SP_QUICK, "SP_TOWERMATCH" => SP_TRIAL, "SP_TUTORIAL" => SP_TUTORIAL}
  MP_GAME_TYPES = {MP_RANKED => true, MP_UNRANKED => true, MP_QUICK => true}

  [:white, :black].each do |side|
    key :"#{side}_stats", Hash, :default => {}
    key :"#{side}_gold", Hash, :default => {}
    key :"#{side}_rounds", Array, :default => []
    key :"#{side}_sac_res", Integer, :default => 0
    key :"#{side}_sac_cards", Integer, :default => 0
    key :"#{side}_resources", Array, :default => []
    key :"#{side}_res_totals", Hash, :default => {}
    key :"#{side}_cards", Array, :default => []
    key :"#{side}_rating", Integer
    key :"#{side}_rate_chg", Integer
    key :"#{side}_time", Integer
    key :"#{side}_name", String
    key :"#{side}_id", String
  end

  key :player_ids, Array, :default => []

  key :game_resources, Array, :default => []
  key :game_type, Integer
  key :game_timer, Integer
  key :game_rounds, Integer
  key :game_length, Integer
  key :game_id, Integer

  key :downloads, Integer

  key :difficulty, Integer

  key :perspective, Integer

  key :surrender, Integer
  key :winner, Integer

  key :played_at, Time

  belongs_to :game_version

  timestamps!

  def multiplayer?
    MP_GAME_TYPES[self.game_type]
  end

  def ranked?
    self.game_type == MP_RANKED and self.white_rating? and self.black_rating?
  end

  def file_path
    if Rails.env.production?
      "/var/www/vhosts/scrollspost/current/public/system/replays/#{self.game_id}-#{(self.perspective == WHITE ? "white" : "black")}.spr"
    else
      Rails.root.join("public", "system", "replays", "#{self.game_id}-#{(self.perspective == WHITE ? "white" : "black")}.spr")
    end
  end
end