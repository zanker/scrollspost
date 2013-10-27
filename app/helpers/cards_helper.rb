module CardsHelper
  def render_card_data(field, &block)
    if !@live_card or @live_card[field] == @card_data[field]
      if block_given?
        capture_haml(@card_data, &block)
      else
        @card_data[field]
      end
    elsif block_given?
      show_diff_html(capture_haml(@card_data, &block), capture_haml(@live_card, &block))
    else
      show_diff_html(@card_data[field], @live_card[field])
    end
  end

  def show_diff_html(old, live)
    old = content_tag(:div, "#{content_tag(:div, "#{t("version", :version => @game_version)}:", :class => :version)} #{old}".html_safe, :class => :old)
    new = content_tag(:div, "#{content_tag(:div, "#{t("live")}:", :class => :version)} #{live}".html_safe, :class => :new)
    content_tag(:div, old << new, :class => :diff)
  end
end