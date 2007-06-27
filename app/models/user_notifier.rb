class UserNotifier < ActionMailer::Base
  def forgot_password(user)
    setup_email(user)
    @subject    += 'Request to change your password'
    @body[:url]  = "#{SITE_URL}site/account/reset_password/#{ user.password_reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject    += 'Your password has been reset'
  end

  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "#{SITE_URL}site/account/activate/#{user.activation_code}"
  end

  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{SITE_URL}"
  end

  def item_flagged(user, flag, item_url, flagging_user, message)
    setup_email(user)
    @subject    += "Item flagged #{flag} for moderation."
    @body[:url]  = item_url
    @body[:flagging_user]  = flagging_user
    @body[:flag] = flag
    @body[:message] = message
  end

  def banned(user)
    setup_email(user)
    @subject    += 'Your account has been banned!'
    @body[:url]  = "#{SITE_URL}"
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "#{NOTIFIER_EMAIL}"
    @subject     = "#{SITE_NAME} "
    @sent_on     = Time.now
    @body[:user] = user
  end
end
