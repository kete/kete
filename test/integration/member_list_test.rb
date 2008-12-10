require File.dirname(__FILE__) + '/integration_test_helper'

class MemberListTest < ActionController::IntegrationTest

  context "A Baskets Member List" do

    setup do
      add_admin_as_super_user
      add_bob_as_moderator_to(@@site_basket)
      add_joe_as_member_to(@@site_basket)

      login_as('admin', 'test')
    end

    should "have links to various role types" do
      visit "/site/members/list"
      body_should_contain "Site Members"
      body_should_contain "1 member"
      body_should_contain "1 moderator"
      body_should_contain "1 site administrator"
      body_should_contain "1 technical administrator"
      body_should_not_contain "Currently no Members"
    end

    should "have an RSS feed" do
      visit "/site/members/list"
      body_should_contain "RSS feed for these items"
      click_link "RSS feed for these items"
      body_should_contain "Site - Latest 50 Members"
      body_should_contain "joe"
    end

  end

end
