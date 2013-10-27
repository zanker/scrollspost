class Api::V1::UsersController < Api::V1::BaseController
  def exists
    if params[:email].to_s !~ /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
      render :text => "2"
    elsif User.where(:email => params[:email].to_s.downcase).exists?
      render :text => "1"
    else
      render :text => "0"
    end
  end

  def create
    if params[:name].blank? or params[:uid].blank? or params[:id].blank?
      return render :json => {:errors => {:email => [t("sessions.new.data_invalid")]}, :attributes => {:email => t(".email")}, :scope => "user"}
    end

    user = User.new
    user.email = params[:email].to_s.downcase
    user.password = user.password_confirmation = params[:password].to_s
    user.remember_token = SecureRandom.base64(60).tr("+/=", "pqr")

    if user.valid?
      require "bcrypt"
      user.encrypted_password = BCrypt::Password.create(user.password, :cost => CONFIG[:bcrypt_cost])

      account = ScrollAccount.new
      account.user_id = user._id
      account.name = params[:name].to_s
      account.uid = params[:uid].to_s
      account.scroll_id = params[:id].to_s
      account.save(:validate => false)

      user.save(:validate => false)
      render :json => {:api_key => user.write_api_key, :user_id => user._id, :verif_key => user.verif_key}
    else
      respond_with_model(user)
    end
  end

  def login
    user = User.where(:email => params[:email].to_s.downcase).only(:encrypted_password, :write_api_key, :verif_key).first
    unless user
      return render :json => {:errors => {:email => [t("sessions.new.email_invalid")]}, :attributes => {:email => t(".email")}, :scope => "user"}
    end

    if params[:name].blank? or params[:uid].blank? or params[:id].blank?
      return render :json => {:errors => {:email => [t("sessions.new.data_invalid")]}, :attributes => {:email => t(".email")}, :scope => "user"}
    end

    require "bcrypt"
    bcrypt = BCrypt::Password.new(user.encrypted_password)
    unless bcrypt == params[:password].to_s
      return render :json => {:errors => {:password => [t("sessions.new.password_invalid")]}, :attributes => {:password => t(".password")}, :scope => "user"}
    end

    # Create an account for them if they didn't have one
    unless ScrollAccount.where(:user_id => user._id).exists?
      account = ScrollAccount.new
      account.user_id = user._id
      account.name = params[:name].to_s
      account.uid = params[:uid].to_s.gsub(/[^a-z0-9]/, "")
      account.scroll_id = params[:id].to_s.gsub(/[^a-z0-9]/, "")
      account.save(:validate => false)
    end

    render :json => {:api_key => user.write_api_key, :user_id => user._id, :verif_key => user.verif_key}
  end
end