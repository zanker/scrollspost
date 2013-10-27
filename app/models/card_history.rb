class CardHistory
  include MongoMapper::Document

  key :card_id, Integer

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

  key :total_changes, Integer

  belongs_to :game_version
  belongs_to :live_card

  def has_stats?
    self.category == Card::CATEGORY_MAP["creature"] or self.category == Card::CATEGORY_MAP["structure"]
  end

  def rarity_key
    Card::RARITY_MAP[self.rarity]
  end
end