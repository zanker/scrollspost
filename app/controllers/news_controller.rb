class NewsController < ApplicationController
  def show
    @post = Post.where(:slug => params[:slug].to_s).first
    return render_404 unless @post
    return unless stale?(:public => true, :etag => "#{cookies[:nt]}#{@post.cache_key}")

  end

  def index
    cookies.signed[:nt] = {:value => Post.last_post}
    return unless stale?(:etag => "#{flash[:alert] || flash[:success] || flash[:notice]}#{cookies.signed[:nt]}#{params[:page]}#{current_user ? current_user._id : ""}")

    @posts = Post.sort(:created_at.desc).limit(CONFIG[:limits][:news])
    if params[:page].to_i > 0
      @posts = @posts.skip((params[:page].to_i - 1) * CONFIG[:limits][:news])
    end
  end
end