require File.dirname(__FILE__) + '/integration_test_helper'

class CommentsTest < ActionController::IntegrationTest

  context "Adding comments" do

    setup do
      @site_basket = Basket.find_by_urlified_name('site')
      @comment_basket = create_new_basket :name => 'Comment Basket'
      @topic = Topic.create(:title => 'Commentable Topic', :topic_type_id => 1, :basket_id => @comment_basket.id)
      @topic.creator = User.first
      @topic_url = "/#{@comment_basket.urlified_name}/topics/show/#{@topic.id}"
      add_jake_as_regular_user
      login_as(:jake)
    end

    should "be allowed when non member comments are enabled" do
      @comment_basket.update_attribute(:allow_non_member_comments, true)
      should_be_able_to_add_comment
    end

    should "not be allowed when non member comments are disabled" do
      @comment_basket.update_attribute(:allow_non_member_comments, false)
      should_not_be_able_to_add_comment
    end

    should "be allowed when non member comments inherit from site and site is enabled" do
      @comment_basket.update_attribute(:allow_non_member_comments, nil)
      @site_basket.update_attribute(:allow_non_member_comments, true)
      should_be_able_to_add_comment
    end

    should "not be allowed when non member comments inherit from site and site is disabled" do
      @comment_basket.update_attribute(:allow_non_member_comments, nil)
      @site_basket.update_attribute(:allow_non_member_comments, false)
      should_not_be_able_to_add_comment
    end

  end

  private

  def should_be_able_to_add_comment
    visit @topic_url
    click_link 'join this discussion'
    body_should_contain 'New discussion'
    fill_in 'comment_title', :with => 'Test Comment'
    fill_in 'comment_description', :with => 'Test Description'
    click_button 'Save'
    body_should_contain 'Test Comment'
    body_should_contain 'Test Description'
  end

  def should_not_be_able_to_add_comment
    visit @topic_url
    click_link 'join this discussion'
    body_should_contain 'Sorry, you need to be a member to leave a comment in this basket.'
    body_should_contain 'Permission Denied'
  end

end
