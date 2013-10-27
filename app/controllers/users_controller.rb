class UsersController < ApplicationController
  before_filter :require_logged_out

  def create
    require "bcrypt"

    user = User.new
    user.email = params[:email].to_s.downcase
    user.password = params[:password].to_s.strip
    user.password_confirmation = params[:password_confirmation].to_s.strip
    user.remember_token = SecureRandom.base64(60).tr("+/=", "pqr")
    user.current_sign_in_ip = request.ip
    user.current_sign_in_at = Time.now.utc

    # Move over the analytics id into the user model too
    if cookies.signed[:aid]
      user.analytics_id = cookies.signed[:aid]
    end

    # We're good!
    if user.valid?
      user.encrypted_password = BCrypt::Password.create(user.password, :cost => CONFIG[:bcrypt_cost])
      user.save(:validate => false)

      StatTracker.increment("user.signups/total")

      reset_session
      session[:user_id] = user._id.to_s
      cookies.permanent.signed[:remember_token] = {:value => user.remember_token, :httponly => true}
      cookies.permanent.signed[:aid] = user.analytics_id
    end

    respond_with_model(user, :created)
  end

  def new
    @user = User.new

  end
end