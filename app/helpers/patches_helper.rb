module PatchesHelper
  def aggregate_cards(type, version, criteria)
    changes = {}

    last_version = nil
    if type == "changed"
      last_version = GameVersion.where(:_id.ne => version._id, :created_at.lte => version.created_at).sort(:created_at.desc).only(:version).first
      criteria = criteria.where(:historic_game_version_ids => last_version._id) if last_version
    end

    if type != "changed" or last_version
      criteria.only(:card_id, :name, :rarity, :costs).sort(:costs.asc, :rarity.desc, :name.asc).each do |card|
        if !last_version
          path = cards_path(card.card_id, card.name.parameterize)
        else
          path = cards_show_old_path(card.card_id, card.name.parameterize, :version => last_version.version.parameterize)
        end

        card.costs.each do |resource|
          changes[resource] ||= []
          changes[resource] << link_to(card.name, path, :class => "card-tt rarity-#{card.rarity}", "data-card-id" => card.card_id)
        end
      end
    end

    html = content_tag(:strong, t("patches.index.#{type}_cards"), :class => :gold)

    if changes.empty?
      html << " " << t(".no_#{type}_cards")
    else
      changes.each do |resource, cards|
        list = content_tag(:div, "", :class => "resources size-16 resource-#{resource}").html_safe
        list << " " << cards.join(", ").html_safe

        html << content_tag(:div, list, :class => "resource-row")
      end
    end

    html
  end
end