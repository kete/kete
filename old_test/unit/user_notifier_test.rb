# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

::ActionController::UrlWriter.module_eval do
  default_url_options[:host] = 'www.example.com'
end

class UserNotifierTest < ActionMailer::TestCase
  context "When sending an item_flagged_for email" do
    setup do
      @user = User.first
      UserNotifier.deliver_item_flagged_for(@user, 'http://www.example.com/', 'pending', @user, @user, 1, 'test message')
      @email_body = ActionMailer::Base.deliveries.first.body
    end

    should "have all the necessary details" do
      assert @email_body.include?(@user.user_name)
      assert @email_body.include?(@user.email)
      assert @email_body.include?('Revision # 1 of this item as pending')
      assert @email_body.include?('http://www.example.com/')
      assert @email_body.include?('test message')
    end
  end

  context "When sending an pending_review_for email" do
    setup do
      @user = User.first
      UserNotifier.deliver_pending_review_for(1, @user)
      @email_body = ActionMailer::Base.deliveries.first.body
    end

    should "have all the necessary details" do
      assert @email_body.include?(@user.user_name)
      assert @email_body.include?('Revision # 1 of this item is pending')
    end
  end

  context "When invoking the do_notifications_if_pending method" do
    setup do
      @user = User.first
      set_constant :FREQUENCY_OF_MODERATION_EMAIL, 'instant'

      @topic = Topic.new(:title => "Version 1", :description => "Version 1", :topic_type_id => 1, :basket_id => 1)
      @topic.instance_eval { def fully_moderated?; true; end }
      @topic.save!
      @topic.reload

      @topic.do_notifications_if_pending(1, User.first)
    end

    should "have sent two emails" do
      assert_equal 2, ActionMailer::Base.deliveries.size
    end

    should "have all the necessary details in the first email" do
      email_body = ActionMailer::Base.deliveries.first.body
      assert email_body.include?(@user.user_name)
      assert email_body.include?('Revision # 1 of this item is pending')
    end

    should "have all the necessary details in the second email" do
      email_body = ActionMailer::Base.deliveries.last.body
      assert email_body.include?(@user.user_name)
      assert email_body.include?(@user.email)
      assert email_body.include?('Revision # 1 of this item as pending')
      assert email_body.include?("http://www.example.com/site/topics/history/#{@topic.id}")
    end
  end
end
