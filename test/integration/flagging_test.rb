require File.dirname(__FILE__) + '/integration_test_helper'

class FlaggingTest < ActionController::IntegrationTest

  # start with handling simplest case
  # a user should be able to flag an item
  # user is told moderator will review
  # item ends up listed under moderate/list action
  context "A normal user" do

    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      # Create a test item
      @item = new_topic
    end

    should "be able to flag item from item page" do
      visit "/site/topics/show/#{@item.id}"
      body_should_contain "Flag as: "
      body_should_contain "inaccurate"
      click_link "inaccurate"
      fill_in "message_", :with => "message for moderator"
      click_button "Flag"
      body_should_contain "A moderator has been notified and will review the item in question."
      add_marci_as_super_user
      login_as('marci')
      visit "/site/moderate/list"
      body_should_contain "/site/topics/preview/#{@item.id}?version=1"
    end
  end
end
