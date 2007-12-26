class MailModeratorsWorker < BackgrounDRb::MetaWorker
  set_worker_name :mail_moderators_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
    logger.info("worker created")
    if (FREQUENCY_OF_MODERATION_EMAIL.is_a?(Integer) or FREQUENCY_OF_MODERATION_EMAIL.is_a?(Float)) and FREQUENCY_OF_MODERATION_EMAIL > 0
      # FREQUENCY_OF_MODERATION_EMAIL is in hours (we allow decimals)
      # so multiply it by 60 * 60 to get our seconds arg value
      frequency_in_seconds = FREQUENCY_OF_MODERATION_EMAIL * 60 * 60

      frequency_in_seconds = frequency_in_seconds.to_i

      logger.info("frequency_in_seonds => #{frequency_in_seconds.to_s}")
      add_periodic_timer(frequency_in_seconds) { mail_moderators }
    end
  end

  # periodically call the user_notifier for mailing administrators
  # the list of pending revisions
  # based on a system setting
  def mail_moderators
    logger.info("in mail moderators")
    Basket.find(:all).each do |basket|
      logger.info("basket: #{basket.name}")
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
