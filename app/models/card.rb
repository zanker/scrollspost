class Card
  include MongoMapper::Document

  CATEGORY_MAP = {"enchantment" => 0, "spell" => 1, "creature" => 2, "structure" => 3}
  REVERSE_CATEGORY_MAP = Hash[CATEGORY_MAP.to_a.map {|r| r.reverse}]

  RESOURCES = [:order, :growth, :energy, :decay]
  RESOURCE_MAP = {"order" => :order, "growth" => :growth, "energy" => :energy, "decay" => :decay}

  RARITY_MAP = {0 => "common", 1 => "uncommon", 2 => "rare"}
  REVERSE_RARITY_MAP = Hash[RARITY_MAP.to_a.map {|r| r.reverse}]

  PRICING_FIELDS = ["pricing.h1", "pricing.d1", "pricing.d3", "pricing.d7", "pricing.d14", "pricing.d30"]

  key :card_id, Integer
  key :hash, Binary

  key :name, String
  key :desc, String
  key :flavor, String

  key :types, Array

  key :category, Integer

  key :rules, Array
  key :passive_rule_ids, Array
  key :ability_ids, Array

  key :rarity, Integer

  key :hp, Integer
  key :attack, Integer
  key :cooldown, Integer

  key :cost_order, Integer
  key :cost_decay, Integer
  key :cost_growth, Integer
  key :cost_energy, Integer
  key :total_cost, Integer

  key :costs, Array

  key :available, Boolean

  key :target, String

  key :image_id, Integer
  key :anim_bundle_id, Integer
  key :anim_prev_img_id, Integer
  key :anim_prev_info, Array

  key :store, Hash, :default => {}
  key :store_updated_at, Time

  key :pricing, Hash, :default => {}
  key :price_seen_at, Time
  key :price_updated_at, Time

  key :last_game_version_id, BSON::ObjectId
  key :added_game_version_id, BSON::ObjectId
  key :historic_game_version_ids, Array, :default => []

  timestamps!

  def has_stats?
    self.category == CATEGORY_MAP["creature"] or self.category == CATEGORY_MAP["structure"]
  end

  def rarity_key
    RARITY_MAP[self.rarity]
  end
end