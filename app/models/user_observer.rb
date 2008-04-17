class UserObserver < ActiveRecord::Observer
  def after_create(user)
    if REQUIRE_ACTIVATION
      UserNotifier.deliver_signup_notification(user)
    else
      user.activate
      user.notified_of_activation
    end
  end

  def after_save(user)
    UserNotifier.deliver_banned(user) unless user.banned_at.nil?
    UserNotifier.deliver_activation(user) if user.recently_activated?
    UserNotifier.deliver_forgot_password(user) if user.recently_forgot_password?
    UserNotifier.deliver_reset_password(user) if user.recently_reset_password?
  end
end
