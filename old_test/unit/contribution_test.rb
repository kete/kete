require File.dirname(__FILE__) + '/../test_helper'

class ContributionTest < ActiveSupport::TestCase
  # fixtures preloaded

  # join model
  # all assertions and other stuff handled by sides of the join

  context "When something is created by the anonymous user" do
    setup do
      @anon_user = User.find_by_login('anonymous')
      @not_original_email = "billg@microsoft.com"
      @not_original_name = "Bill Gates"
      @not_original_website = "http://microsoftie.com"

      @anon_user.email = @not_original_email
      @anon_user.display_name = @not_original_name
      @anon_user.website = @not_original_website

      @basket = Basket.first
      @last_topic_in_site = @basket.topics.last
      @comment = Comment.create!(
        :title => "created by anonymous",
        :description => "test",
        :basket => @basket,
        :commentable_type => 'Topic',
        :commentable_id => @last_topic_in_site
      )
      @comment.creator = @anon_user
    end

    should "have an email address stored for the contribution" do
      @anon_user.reload
      assert_not_equal @anon_user.email, @not_original_email

      @anon_comment = @anon_user.contributions.last
      assert_equal @anon_comment.email_for_anonymous, @not_original_email
    end

    should "requesting creator's email will get email_for_anonymous" do
      assert_equal @comment.creator.email, @not_original_email
    end

    should "have an name stored for the contribution" do
      @anon_user.reload
      assert_not_equal @anon_user.resolved_name, @not_original_name

      @anon_comment = @anon_user.contributions.last
      assert_equal @anon_comment.name_for_anonymous, @not_original_name
    end

    should "requesting creator's display_name will get name_for_anonymous" do
      assert_equal @comment.creator.resolved_name, @not_original_name
    end

    should "have an website stored for the contribution" do
      anon_user = User.find_by_login('anonymous')
      assert_not_equal anon_user.website, @not_original_website

      anon_comment = anon_user.contributions.last
      assert_equal anon_comment.website_for_anonymous, @not_original_website
    end

    should "requesting creator's website will get website_for_anonymous" do
      assert_equal @comment.creator.website, @not_original_website
    end
  end
end
