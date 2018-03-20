# frozen_string_literal: true

class MailModeratorsWorker < BackgrounDRb::MetaWorker
  set_worker_name :mail_moderators_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
    frequency_of_moderation_email = SystemSetting.frequency_of_moderation_email
    if (frequency_of_moderation_email.is_a?(Integer) || frequency_of_moderation_email.is_a?(Float)) && (frequency_of_moderation_email > 0)
      # frequency_of_moderation_email is in hours (we allow decimals)
      # so multiply it by 60 * 60 to get our seconds arg value
      frequency_in_seconds = frequency_of_moderation_email * 60 * 60

      frequency_in_seconds = frequency_in_seconds.to_i

      add_periodic_timer(frequency_in_seconds) { mail_moderators }
    end
  end

  # periodically call the user_notifier for mailing administrators
  # the list of pending revisions
  # based on a system setting
  def mail_moderators
    Basket.find(:all).each do |basket|
      # get revisions needing moderator review
      revisions = basket.all_disputed_revisions
      if revisions.size > 0
        basket.moderators_or_next_in_line.each do |moderator|
          UserNotifier.deliver_review_flagged_for(basket, moderator)
        end
      end
    end
  end
end
