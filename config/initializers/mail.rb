if Rails.env.production?
  auth = {
    :address => "smtp.mandrillapp.com",
    :port => 25,
    :enable_starttls_auto => true,
    :user_name => "secret",
    :password  => "secret",
    :authentication => "login",
    :domain => "secret",
  }

  ActionMailer::Base.add_delivery_method :smtp, Mail::SMTP, auth

  ActionMailer::Base.delivery_method = :smtp

  Mail.defaults do
    delivery_method :smtp
  end

else
  ActionMailer::Base.delivery_method = :test

  Mail.defaults do
    delivery_method :test
  end
end