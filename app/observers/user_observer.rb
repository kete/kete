# frozen_string_literal: true

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    if SystemSetting.require_activation?
      if SystemSetting.administrator_activates?
        Role.find_by_name('site_admin').users.each do |admin|
          UserNotifier.notification_to_administrators_of_new(user, admin).deliver
        end
      else
        UserNotifier.signup_notification(user).deliver
      end
    else
      user.activate
      user.notified_of_activation
    end
  end

  def after_save(user)
    UserNotifier.banned(user).deliver unless user.banned_at.nil?
    UserNotifier.activation(user).deliver if user.recently_activated?
    UserNotifier.forgot_password(user).deliver if user.recently_forgot_password?
    UserNotifier.reset_password(user).deliver if user.recently_reset_password?
  end
end
