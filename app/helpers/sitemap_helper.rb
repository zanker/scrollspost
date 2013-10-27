module SitemapHelper
  def url(location, priority, lastmod=nil, frequency=nil)
    html = ""
    html << content_tag(:loc, location)
    html << content_tag(:priority, priority)
    if lastmod
      lastmod = Time.at(lastmod) if lastmod.is_a?(Fixnum)
      html << content_tag(:lastmod, lastmod.to_s(:sitemap))
    end

    html << content_tag(:changefreq, frequency)
    content_tag(:url, html.html_safe)
  end
end
