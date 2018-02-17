class UserNotifier < ActionMailer::Base
  default from: SystemSetting.notifier_email.to_s

  # kludge for A_S and rails 2.0
  def generic_view_paths
    []
  end

  def forgot_password(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.password_change')
    @url = "#{SystemSetting.site_url}site/account/reset_password/#{user.password_reset_code}"

    mail(to: @recipients, subject: @subject)
  end

  def reset_password(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.password_reset')

    mail(to: @recipients, subject: @subject)
  end

  def signup_notification(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.activate_account')
    @url = "#{SystemSetting.site_url}site/account/activate/#{user.activation_code}"

    mail(to: @recipients, subject: @subject)
  end

  def notification_to_administrators_of_new(user, admin)
    setup_email(admin)
    @subject += I18n.t('user_notifier_model.review_new_account', new_user: user.resolved_name)
    @new_user = user
    @url = "#{SystemSetting.site_url}site/account/show/#{user.id}"

    mail(to: @recipients, subject: @subject)
  end

  def activation(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.account_activated')
    @url = SystemSetting.site_url.to_s

    mail(to: @recipients, subject: @subject)
  end

  def banned(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.account_banned')
    @url = SystemSetting.site_url.to_s

    mail(to: @recipients, subject: @subject)
  end

  def email_to(recipient, sender, subject, message, from_basket = nil)
    setup_email(sender)
    @recipients = recipient.email
    @reply_to = sender.email
    @subject += I18nt('user_notifier_model.user_sent_message', user_name: sender.user_name)
    @recipient = recipient
    @subject = subject
    @message = message
    @from_basket = from_basket

    mail(to: @recipients, subject: @subject, reply_to: @reply_to)
  end

  # notifications for basket joins
  def join_notification_to(recipient, sender, basket, type)
    setup_email(recipient)
    @sender = sender
    @basket = basket

    case type
    when 'joined'
      @subject += I18n.t(
        'user_notifier_model.user_joined',
        user_name: sender.user_name, basket_name: basket.name
      )
      @template_name = 'join_policy/member'
    when 'request'
      @subject += I18n.t(
        'user_notifier_model.user_requested',
        user_name: sender.user_name, basket_name: basket.name
      )
      @template_name = 'join_policy/request'
    when 'approved'
      @subject += I18n.t('user_notifier_model.membership_accepted', basket_name: basket.name)
      @template_name = 'join_policy/accepted'
    when 'rejected'
      @subject += I18n.t('user_notifier_model.membership_rejected', basket_name: basket.name)
      @template_name = 'join_policy/rejected'
    else
      raise 'Invalid membership notification type. joined, request, approved and rejected only.'
    end

    mail(to: @recipients, subject: @subject, template_name: @template_name)
  end

  # notifications for flagging/moderation
  def item_flagged_for(moderator, url, flag, flagging_user, submitter, revision, message)
    setup_email(moderator)
    @subject += I18n.t('user_notifier_model.item_flagged_with', flag: flag)
    setup_body_with(revision, url, message, submitter)
    @flagging_user = flagging_user
    @flag = flag

    mail(to: @recipients, subject: @subject)
  end

  def pending_review_for(revision, submitter)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.pending_moderation', flag: SystemSetting.pending_flag)
    @revision = revision

    mail(to: @recipients, subject: @subject)
  end

  def review_flagged_for(basket, moderator)
    setup_email(moderator)
    @subject += I18n.t('user_notifier_model.awaiting_review', basket_name: basket.name)
    @basket = basket
    @disputed_revisions = basket.all_disputed_revisions

    mail(to: @recipients, subject: @subject)
  end

  def rejection_of(revision, url, submitter, rejection_message)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.rejected_submission', flag: SystemSetting.rejected_flag)
    setup_body_with(revision, url, rejection_message)

    mail(to: @recipients, subject: @subject)
  end

  def approval_of(revision, url, submitter, approval_message)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.revision_live')
    setup_body_with(revision, url, approval_message)

    mail(to: @recipients, subject: @subject)
  end

  def reviewing_of(revision, url, submitter, rejection_message)
    setup_email(submitter)
    @subject += I18n.t('user_notifier_model.reviewed_submission', flag: SystemSetting.reviewed_flag)
    setup_body_with(revision, url, rejection_message)

    mail(to: @recipients, subject: @subject)
  end

  # notications for baskets
  def basket_notification_to(recipient, sender, basket, type)
    setup_email(recipient)
    @sender = sender
    @basket = basket

    case type
    when 'created'
      @subject += I18n.t(
        'user_notifier_model.basket_created',
        user_name: sender.user_name, basket_name: basket.name
      )
      @needs_approval = false
      @template_name = 'basket_create_policy/created'
    when 'request'
      @subject += I18n.t(
        'user_notifier_model.basket_requested',
        user_name: sender.user_name, basket_name: basket.name
      )
      @needs_approval = true
      @template_name = 'basket_create_policy/created'
    when 'approved'
      @subject += I18n.t('user_notifier_model.basket_approved', basket_name: basket.name)
      @template_name = 'basket_create_policy/approved'
    when 'rejected'
      @subject += I18n.t('user_notifier_model.basket_rejected', basket_name: basket.name)
      @template_name = 'basket_create_policy/rejected'
    else
      raise 'Invalid basket notification type. created, request, approved and rejected only.'
    end

    mail(to: @recipients, subject: @subject, template_name: @template_name)
  end

  def login_changed(user)
    setup_email(user)
    @subject += I18n.t('user_notifier_model.login_changed')
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

      if basket.setting(:private_item_notification_show_title) == true
        @subject += I18n.t("user_notifier_model.private_#{type}_with_title", basket_name: basket.name, item_title: item.title)
        @title = item.title
      else
        @subject += I18n.t("user_notifier_model.private_#{type}", basket_name: basket.name)
        @title = nil
      end

      @summary = if item.respond_to?(:short_summary) && basket.setting(:private_item_notification_show_short_summary) == true
        item.short_summary
      else
        nil
                 end

      @item = item
      @url = url
      @type = type
      @template_name = 'private_item_notification'

      mail(to: @recipients, subject: @subject, template_name: @template_name)
    end
  end

  protected

  def setup_email(user)
    @recipients  = user.email.to_s
    @subject     = "#{SystemSetting.site_name} "

    @user = user
    @recipient = user # less confusing than user
  end

  def setup_body_with(revision, url, message, submitter = nil)
    @revision = revision
    @url = url
    @submitter = submitter
    @message = message
  end

  # James - 2008-06-29
  # Work around to fix active_scaffold exceptions
  class << self
    def uses_active_scaffold?
      false
    end
  end
end
