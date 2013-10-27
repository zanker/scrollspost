class SitemapController < ApplicationController
  def index
    render :layout => false, :formats => :xml
  end
end