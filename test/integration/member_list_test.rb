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

    should "allow members to be added to it" do
      visit '/about/members/list'
      fill_in 'search_name', :with => 'john'
      click_button 'Search'
      check "user_#{@john.to_param}_add_checkbox"
      click_button 'Add members'
      body_should_contain 'Successfully added new member.'
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

    context 'when there is one basket admin for the site basket, a site admin' do

      setup do
        add_jane_as_admin_to(@@site_basket)
      end

      should 'be able to promote that single basket admin for site basket to site admin ' do
        visit '/site/members/list'
        click_link '1 administrator'
        body_should_contain 'jane'
        body_should_contain Regexp.new("<a .+(change_membership_type).+(role=site_admin).+>Site Admin</a>")
        click_link 'Site Admin'
        # goes to site member list after changing the user's role
        # flash message plus new number for role should indicate that our change role was successful
        body_should_contain '2 site administrators'
        # thought there was a specific macro for flash, but can't find it
        body_should_contain 'User successfully changed role.'
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

    should "only allow site admins to sort by login" do
      @@site_basket.settings[:memberlist_policy] = 'at least member'
      visit "/site/members/list"
      body_should_contain Regexp.new("<a (.+)>User name</a>(\s+)or(\s+)<a (.+)>Login</a>")
      login_as('joe')
      visit "/site/members/list"
      body_should_not_contain Regexp.new("<a (.+)>User name</a>(\s+)or(\s+)<a (.+)>Login</a>")
      body_should_contain Regexp.new("<a (.+)>User name</a>")
    end

    context "when being sorted" do

      setup do
        @@sorting_basket = create_new_basket({ :name => 'Sorting Basket' })
        add_user1_as_member_to(@@sorting_basket, { :display_name => 'Brian' })
        add_user2_as_member_to(@@sorting_basket, { :display_name => 'Josh' })
        add_user3_as_member_to(@@sorting_basket, { :display_name => 'Amy' })
      end

      should "sort correctly by resolved name" do
        visit '/sorting_basket/members/list?direction=asc&order=users.resolved_name'
        # Surounding the names with >< is a quick way to check the name is within a tag (likely <a></a>)
        body_should_contain_in_order(['>Amy<', '>Brian<', '>Josh<'], '<td class="member_avatar">', :offset => 1)
      end

      should "sort correctly by login" do
        visit '/sorting_basket/members/list?direction=asc&order=users.login'
        # Surounding the names with () is a quick way to check it's not part of a link
        body_should_contain_in_order(['(user1)', '(user2)', '(user3)'], '<td class="member_avatar">', :offset => 1)
      end

    end

  end

  context "A non-site basket memberlist" do

    setup do
      add_admin_as_super_user
      login_as(:admin)
      @@non_site_basket = create_new_basket({ :name => 'Non Site Basket' })
    end

    context "when there is only one admin in the basket" do

      setup do
        add_lily_as_admin_to @@non_site_basket
        add_gary_as_member_to @@non_site_basket
      end

      should "be able to remove members successfully" do
        visit "/#{@@non_site_basket.urlified_name}/members/list"
        click_link 'Remove from basket'
        body_should_contain 'Successfully removed user from Non Site Basket.'
      end

      should "not be able to remove last admin" do
        visit "/#{@@non_site_basket.urlified_name}/members/list?type=admin"
        body_should_not_contain 'Remove from basket'
      end

    end

    context "when there is two admins in the basket" do

      setup do
        add_lily_as_admin_to @@non_site_basket
        add_jim_as_admin_to @@non_site_basket
        add_gary_as_member_to @@non_site_basket
      end

      should "be able to remove members successfully" do
        visit "/#{@@non_site_basket.urlified_name}/members/list"
        click_link 'Remove from basket'
        body_should_contain 'Successfully removed user from Non Site Basket.'
      end

      should "be able to remove one admin" do
        visit "/#{@@non_site_basket.urlified_name}/members/list?type=admin"
        click_link 'Remove from basket'
        body_should_contain 'Successfully removed user from Non Site Basket.'
        visit "/#{@@non_site_basket.urlified_name}/members/list?type=admin"
        body_should_not_contain 'Remove from basket'
      end

    end

  end

end
