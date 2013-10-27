class Notification < ActionMailer::Base
  default(:from => "Support <support@yourdomain.com>")

  def internal_alert(subject, body)
    mail(:from => "alerts@yourdomain.com", :to => "alerts@yourdomain.com", :subject => subject, :body => body)
  end
end
