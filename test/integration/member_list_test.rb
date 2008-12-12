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

    context 'when view policy is set to at least admin' do

      setup do
        @@site_basket.settings[:memberlist_policy] = 'at least admin'
      end

      should 'allow admins access' do
        visit '/site/members/list'
        body_should_contain 'Site Members'
      end

      should 'deny less than admins access' do
        login_as('bob')
        visit '/site/members/list'
        body_should_contain 'Permission Denied'
      end

    end

    context 'when view policy is set to at least moderator' do

      setup do
        @@site_basket.settings[:memberlist_policy] = 'at least moderator'
      end

      should 'allow moderators access' do
        login_as('bob')
        visit '/site/members/list'
        body_should_contain 'Site Members'
      end

      should 'deny less than moderators access' do
        login_as('joe')
        visit '/site/members/list'
        body_should_contain 'Permission Denied'
      end

    end

    context 'when view policy is set to at least member' do

      setup do
        @@site_basket.settings[:memberlist_policy] = 'at least member'
      end

      should 'allow members access' do
        login_as('joe')
        visit '/site/members/list'
        body_should_contain 'Site Members'
      end

      should 'deny less than members access' do
        login_as('john')
        visit '/site/members/list'
        body_should_contain 'Permission Denied'
      end

    end

    context 'when view policy is set to logged in' do

      setup do
        @@site_basket.settings[:memberlist_policy] = 'logged in'
      end

      should 'allow logged in users access' do
        login_as('john')
        visit '/site/members/list'
        body_should_contain 'Site Members'
      end

      should 'deny less than logged in users access' do
        logout
        visit '/site/members/list'
        body_should_contain 'Permission Denied'
      end

    end

    context 'when view policy is set to all users' do

      setup do
        @@site_basket.settings[:memberlist_policy] = 'all users'
      end

      should 'allow anyone access' do
        logout
        visit '/site/members/list'
        body_should_contain 'Site Members'
      end

    end

  end

end
