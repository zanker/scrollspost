class ParseNews
  include Sidekiq::Worker
  sidekiq_options :queue => :medium, :retry => false

  def perform(version_id)
    version = GameVersion.find(version_id)

    # Cache cards
    cards, regex = {}, []
    Card.only(:name, :card_id, :rarity).each do |card|
      cards[card.name] = card
      regex << Regexp.escape(card.name)
    end

    resources = Card.distinct(:costs).map do |resource|
      ["(#{resource.capitalize})", "(<div class='resources resource-#{resource} size-16'></div> #{resource.capitalize})"]
    end

    # Pull notes
    response = Net::HTTP.get(URI.parse("http://download.scrolls.com/assets/news.txt"))

    notes = response.split("\r\n\r\n---\r\n\r\n")
    notes.shift

    notes.reverse.each do |note|
      patch_log = note =~ /Scrolls Changelog #{version.version}/i
      next unless patch_log

      # Fix colorizing
      note.gsub!(/<color=(#[0-9a-zA-Z]+)>/, '<span style="color: \1">')
      note.gsub!(/style="color: #ffdd88"/, "class='header'")
      note.gsub!(/style="color: #cccccc"/, "class='feature'")
      note.gsub!(/<\/color>/, "</span>")

      # Add icons for resources
      resources.each do |resource|
        note.gsub!(resource[0], resource[1])
      end

      # Card everything
      note.gsub!("Summons a", "**PLACEHOLDER**")
      note.gsub!(/(#{regex.join("|")})/) do |match|
        if cards[match]
          "<a href='http://www.scrollspost.com/scroll/#{cards[match].card_id}/#{match.parameterize}' data-card-id='#{cards[match].card_id}' class='card-tt rarity-#{cards[match].rarity}'>#{match}</a>"
        else
          match
        end
      end
      note.gsub!("**PLACEHOLDER**", "Summons a")

      # Drop the first line
      note.gsub!(/Scrolls Changelog #{version.version}.+\r\n\r\n/i, "")

      version.log = note.strip.gsub("\r\n", "<br>")
      version.save

      break
    end

    unless version.log?
      InternalAlert.deliver(self.class, "Cannot load patch notes #{version_id}", "Failed to load patch ntoes for #{version_id}\n\n#{response}")
    end
  end
end