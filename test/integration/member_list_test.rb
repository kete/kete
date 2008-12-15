require File.dirname(__FILE__) + '/integration_test_helper'

class MemberListTest < ActionController::IntegrationTest

  context 'A Baskets Member List' do

    setup do
      add_admin_as_super_user
      add_bob_as_moderator_to(@@site_basket)
      add_joe_as_member_to(@@site_basket)
      add_john

      login_as('admin')
    end

    should 'have an RSS feed' do
      visit '/site/members/list'
      body_should_contain 'RSS feed for these items'
      click_link 'RSS feed for these items'
      body_should_contain 'Site - Latest 50 Members'
      body_should_contain 'joe'
    end

    context 'when a basket admin or site admin views it' do

      should 'have links to various role types' do
        visit '/site/members/list'
        body_should_contain 'Site Members'
        body_should_contain '1 member'
        body_should_contain '1 moderator'
        body_should_contain '1 site administrator'
        body_should_contain '1 technical administrator'
        body_should_not_contain 'Currently no Members'
      end

    end

    # This wraps 9 different tests of relativly same testing pattern into an easy to manage loop
    member_roles = [
      ['Basket admin', 'at least admin', 'admin'],
      ['Basket moderator', 'at least moderator', 'bob'],
      ['Basket member', 'at least member', 'joe'],
      ['Logged in user', 'logged in', 'john'],
      ['All users', 'all users', nil]
    ]
    member_roles.each_with_index do |role,index|
      title, at_least, user = role[0], role[1], role[2]
      context "when view policy is set to #{at_least}" do
        setup do
          @@site_basket.settings[:memberlist_policy] = "#{at_least}"
        end
        should "allow #{title} access" do
          !user.nil? ? login_as(user) : logout
          visit '/site/members/list'
          body_should_contain 'Site Members'
        end
        if !member_roles[(index + 1)].blank? && !member_roles[(index + 1)][2].blank?
          should "deny less than #{title} access" do
            login_as(member_roles[(index + 1)][2])
            visit '/site/members/list'
            body_should_contain 'Permission Denied'
          end
        end
      end
    end

  end

end
