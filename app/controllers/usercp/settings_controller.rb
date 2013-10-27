class Usercp::SettingsController < Usercp::BaseController
  def edit
    @account = current_user.scroll_accounts.first
  end

  def update
    user = User.where(:_id => current_user._id).first
    user.email = params[:email].to_s
    user.email_market = params[:email_market] != "false"
    if !params[:password].blank? or !params[:password_confirmation].blank?
      user.password = params[:password].to_s
      user.password_confirmation = params[:password_confirmation].to_s
    end

    # Check the account first
    account = current_user.scroll_accounts.first
    if account
      account.steam_name = params[:steam_name].blank? ? nil : params[:steam_name].to_s
      account.channel = params[:channel].blank? ? nil : params[:channel].to_s
      account.haggle = params[:haggle] == "true"
      account.public = params[:public] == "true"
      account.note = params[:note].blank? ? nil : view_context.strip_tags(params[:note].to_s.strip)

      unless account.valid?
        if account.public_changed?
          UserInventory.set({:scroll_account_id => account._id}, :public => account.public)
        end

        return respond_with_model(user)
      end
    end

    # Now the user
    unless user.valid?
      return respond_with_model(user)
    end

    # We're good
    flash[:success] = t("usercp.settings.edit.settings_updated")

    if user.password and user.password_confirmation
      require "bcrypt"
      user.encrypted_password = BCrypt::Password.create(user.password, :cost => CONFIG[:bcrypt_cost])
    end

    user.save(:validate => false)
    account.save(:validate => false) if account

    render :nothing => true, :status => :no_content
  end
end