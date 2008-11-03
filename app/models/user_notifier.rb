class UserNotifier < ActionMailer::Base
  # kludge for A_S and rails 2.0
  def generic_view_paths
    []
  end

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

  def banned(user)
    setup_email(user)
    @subject    += 'Your account has been banned!'
    @body[:url]  = "#{SITE_URL}"
  end

  def email_to(recipient, sender, subject, message, from_basket = nil)
    setup_email(sender)
    @recipients = recipient.email
    @reply_to = sender.email
    @subject += "#{sender.user_name} has sent you a message."
    @body[:recipient] = recipient
    @body[:subject] = subject
    @body[:message] = message
    @body[:from_basket] = from_basket
  end

  # notifications for flagging/moderation
  def item_flagged_for(moderator, flag, url, flagging_user, submitter, revision, message)
    setup_email(moderator)
    @subject += "Item flagged #{flag} for moderation."
    setup_body_with(revision, url, message, submitter)
    @body[:flagging_user]  = flagging_user
    @body[:flag] = flag
  end

  def pending_review_for(revision, submitter)
    setup_email(submitter)
    @subject += "Your submission is #{PENDING_FLAG} moderation."
    @body[:revision] = revision
  end

  def review_flagged_for(basket, moderator)
    setup_email(moderator)
    @subject += "User contributions waiting review in #{basket.name}."
    @body[:basket] = basket
    @body[:disputed_revisions] = basket.all_disputed_revisions
  end

  def rejection_of(revision, url, submitter, rejection_message)
    setup_email(submitter)
    @subject += "A moderator has #{REJECTED_FLAG} your submission."
    setup_body_with(revision, url, rejection_message)
  end

  def approval_of(revision, url, submitter, approval_message)
    setup_email(submitter)
    @subject    += "A moderator has made your submission the live revision."
    setup_body_with(revision, url, approval_message)
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "#{NOTIFIER_EMAIL}"
    @subject     = "#{SITE_NAME} "
    @sent_on     = Time.now
    @body[:user] = user
  end

  def setup_body_with(revision, url, message, submitter = nil)
    @body[:revision] = revision
    @body[:url] = url
    @body[:submitter] = submitter
    @body[:message] = message
  end
  
  
  # James - 2008-06-29
  # Work around to fix active_scaffold exceptions
  class << self
    def uses_active_scaffold?
      false
    end
  end
  
end
