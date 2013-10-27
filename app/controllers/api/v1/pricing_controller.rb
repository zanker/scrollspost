class Api::V1::PricingController < Api::V1::BaseController
  def show
    unless period = PricingController::STAT_PERIOD[params[:period].to_s]
      return render_error(:invalid_period)
    end

    search = CGI::unescape(params[:search].to_s)

    card = Card.where(:name => /#{search}/i).only(:name, :card_id, "pricing.#{period}").first
    unless card
      return render_error(:scroll_not_found)
    end

    render_response(format_card(card, period))
  end

  def index
    unless period = PricingController::STAT_PERIOD[params[:period].to_s]
      return render_error(:invalid_period)
    end

    render_response(Card.only(:name, :card_id, "pricing.#{period}").map do |card|
      format_card(card, period)
    end)
  end

  private
  def format_card(card, period)
    price = {:suggested => 0, :buy => 0, :sell => 0}
    if card.pricing[period]
      price[:suggested] = card.pricing[period]["sug"] || 0
      price[:buy] = card.pricing[period]["buy"] && card.pricing[period]["buy"]["p95"] || 0
      price[:sell] = card.pricing[period]["buy"] && card.pricing[period]["sell"]["p95"] || 0
    end

    if params[:formatting] == "1"
      price[:suggested] = view_context.number_with_delimiter(view_context.round_number(price[:suggested], 5))
      price[:buy] = view_context.number_with_delimiter(view_context.round_number(price[:buy], 5))
      price[:sell] = view_context.number_with_delimiter(view_context.round_number(price[:sell], 5))
    end

    {:card_id => card.card_id, :name => card.name, :price => price}
  end
end