class UserNotifier < ActionMailer::Base
  # kludge for A_S and rails 2.0
  def generic_view_paths
    []
  end

  def forgot_password(user)
    setup_email(user)
    @subject    += I18n.t('user_notifier_model.password_change')
    @body[:url]  = "#{SITE_URL}site/account/reset_password/#{ user.password_reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject    += I18n.t('user_notifier_model.password_reset')
  end

  def signup_notification(user)
    setup_email(user)
    @subject    += I18n.t('user_notifier_model.activate_account')
    @body[:url]  = "#{SITE_URL}site/account/activate/#{user.activation_code}"
  end

  def activation(user)
    setup_email(user)
    @subject    += I18n.t('user_notifier_model.account_activated')
    @body[:url]  = "#{SITE_URL}"
  end

  def banned(user)
    setup_email(user)
    @subject    += I18n.t('user_notifier_model.account_banned')
    @body[:url]  = "#{SITE_URL}"
  end

  def email_to(recipient, sender, subject, message, from_basket = nil)
    setup_email(sender)
    @recipients = recipient.email
    @reply_to = sender.email
    @subject += I18n.t('user_notifier_model.user_sent_message', :user_name => sender.user_name)
    @body[:recipient] = recipient
    @body[:subject] = subject
    @body[:message] = message
    @body[:from_basket] = from_basket
  end

  # notifications for basket joins
  def join_notification_to(recipient, sender, basket, type)
    setup_email(recipient)
    @body[:sender] = sender
    @body[:basket] = basket

    case type
    when 'joined'
      @subject += I18n.t('user_notifier_model.user_joined',
                         :user_name => sender.user_name, :basket_name => basket.name)
      @template = 'user_notifier/join_policy/member'
    when 'request'
      @subject += I18n.t('user_notifier_model.user_requested',
                         :user_name => sender.user_name, :basket_name => basket.name)
      @template = 'user_notifier/join_policy/request'
    when 'approved'
      @subject += I18n.t('user_notifier_model.membership_accepted', :basket_name => basket.name)
      @template = 'user_notifier/join_policy/accepted'
    when 'rejected'
      @subject += I18n.t('user_notifier_model.membership_rejected', :basket_name => basket.name)
      @template = 'user_notifier/join_policy/rejected'
    else
      raise "Invalid membership notification type. joined, request, approved and rejected only."
    end
  end

  # notifications for flagging/moderation
  def item_flagged_for(moderator, url, flag, flagging_user, submitter, revision, message)
    setup_email(moderator)
    @subject += I18n.t('user_notifier_model.item_flagged_with', :flag => flag)
    setup_body_with(revision, url, message, submitter)
    @body[:flagging_user]  = flagging_user
    @body[:flag] = flag
  end

  def pending_review_for(revision, submitter)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.pending_moderation', :flag => PENDING_FLAG)
    @body[:revision] = revision
  end

  def review_flagged_for(basket, moderator)
    setup_email(moderator)
    @subject += I18n.t('user_notifier_model.awaiting_review', :basket_name => basket.name)
    @body[:basket] = basket
    @body[:disputed_revisions] = basket.all_disputed_revisions
  end

  def rejection_of(revision, url, submitter, rejection_message)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.rejected_submission', :flag => REJECTED_FLAG)
    setup_body_with(revision, url, rejection_message)
  end

  def approval_of(revision, url, submitter, approval_message)
    setup_email(submitter)
    @subject    += I18n.t('user_notifier_model.revision_live')
    setup_body_with(revision, url, approval_message)
  end

  def reviewing_of(revision, url, submitter, rejection_message)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.reviewed_submission', :flag => REVIEWED_FLAG)
    setup_body_with(revision, url, rejection_message)
  end

  # notications for baskets
  def basket_notification_to(recipient, sender, basket, type)
    setup_email(recipient)
    @body[:sender] = sender
    @body[:basket] = basket

    case type
    when 'created'
      @subject += I18n.t('user_notifier_model.basket_created',
                         :user_name => sender.user_name, :basket_name => basket.name)
      @body[:needs_approval] = false
      @template = 'user_notifier/basket_create_policy/created'
    when 'request'
      @subject += I18n.t('user_notifier_model.basket_requested',
                         :user_name => sender.user_name, :basket_name => basket.name)
      @body[:needs_approval] = true
      @template = 'user_notifier/basket_create_policy/created'
    when 'approved'
      @subject += I18n.t('user_notifier_model.basket_approved', :basket_name => basket.name)
      @template = 'user_notifier/basket_create_policy/approved'
    when 'rejected'
      @subject += I18n.t('user_notifier_model.basket_rejected', :basket_name => basket.name)
      @template = 'user_notifier/basket_create_policy/rejected'
    else
      raise "Invalid basket notification type. created, request, approved and rejected only."
    end
  end

  def login_changed(user)
    setup_email(user)
    @subject    +=  I18n.t('user_notifier_model.login_changed')
  end

  # define methods
  #   private_item_created
  #   private_item_edited
  #   private_comment_created
  #   private_comment_edited
  ['item_created', 'item_edited', 'comment_created', 'comment_edited'].each do |type|
    define_method "private_#{type}" do |recipient, item, url|
      setup_email(recipient)
      item.private_version!
      basket = item.is_a?(Comment) ? item.commentable.basket : item.basket

      if basket.settings[:private_item_notification_show_title] == true
        @subject += I18n.t("user_notifier_model.private_#{type}_with_title", :basket_name => basket.name, :item_title => item.title)
        @body[:title] = item.title
      else
        @subject += I18n.t("user_notifier_model.private_#{type}", :basket_name => basket.name)
        @body[:title] = nil
      end

      if item.respond_to?(:short_summary) && basket.settings[:private_item_notification_show_short_summary] == true
        @body[:summary] = item.short_summary
      else
        @body[:summary] = nil
      end

      @body[:item] = item
      @body[:url] = url
      @body[:type] = type
      @template = "user_notifier/private_item_notification"
    end
  end

  protected

  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "#{NOTIFIER_EMAIL}"
    @subject     = "#{SITE_NAME} "
    @sent_on     = Time.now
    @body[:user] = user
    @body[:recipient] = user # less confusing than user
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
