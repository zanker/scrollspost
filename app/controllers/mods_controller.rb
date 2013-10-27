class ModsController < ApplicationController
  def download
    mod = Mod.where(:_id => params[:mod_id].to_s).only(:_id).first
    unless mod
      return render_404
    end

    mod.increment(:downloads => 1)

    send_file(mod.file_path, :type => "application/x-msdos-program")
  end

  def mods
    mods = Rails.cache.fetch("mod-list/#{Rails.cache.read("mod-exp")}", :expires_in => 1.hour) do
      Mod.all.map do |mod|
        {:id => mod._id.to_s, :name => mod.name, :description => mod.description, :version => mod.build, :versionCode => mod.version_human, :downloads => mod.downloads}
      end
    end

    render :json => {:msg => :success, :data => mods}
  end

  def repo
    render :json => {
      :msg => :success,
      :data => {:name => "ScrollsPost", :url => "http:\/\/mods.scrollspost.com\/", :version => 1, :mods => 1}
    }
  end
end