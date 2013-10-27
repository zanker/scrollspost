class SessionsController < ApplicationController
  before_filter :require_logged_in, :only => :destroy

  def create
    user = User.where(:email => params[:email].to_s.downcase).only(:encrypted_password, :current_sign_in_at, :analytics_id).first
    unless user
      return render :json => {:errors => {:email => [t("sessions.new.email_invalid")]}, :attributes => {:email => t(".email")}, :scope => "user"}, :status => :bad_request
    end

    require "bcrypt"
    bcrypt = BCrypt::Password.new(user.encrypted_password)
    unless bcrypt == params[:password].to_s.strip
      return render :json => {:errors => {:password => [t("sessions.new.password_invalid")]}, :attributes => {:password => t(".password")}, :scope => "user"}, :status => :bad_request
    end

    StatTracker.increment("user.logins/total");

    # We're good, regenerate tokens and log them in
    remember_token = SecureRandom.base64(60).tr("+/=", "pqr")
    user.set(:remember_token => remember_token, :current_sign_in_ip => request.ip, :current_sign_in_at => Time.now.utc, :last_sign_in_at => user.current_sign_in_at)

    reset_session
    session[:user_id] = user._id.to_s
    cookies.permanent.signed[:remember_token] = {:value => remember_token, :httponly => true}
    cookies.permanent.signed[:aid] = user.analytics_id

    render :nothing => true, :status => :no_content
  end

  def destroy
    current_user.unset(:remember_token)
    reset_session

    redirect_to root_path, :notice => t("sessions.destroy.success")
  end

  def new
    @user = User.new
  end
end