require File.dirname(__FILE__) + '/integration_test_helper'

class ProfilesTest < ActionController::IntegrationTest
  context "The basket profiles functionaltiy" do
    ['site_admin', 'admin'].each do |role|
      context "when logged in as an #{role.humanize}" do
        setup do
          case role
          when 'site_admin'
            add_admin_as_super_user
            login_as(:admin)
          when 'admin'
            add_jill_as_admin_to(@@about_basket)
            login_as(:jill)
          end
        end

        should "not affect access to basket edit" do
          visit "/about/baskets/edit/#{@@about_basket.id}"
          body_should_contain "About Edit"
        end

        should "not affect access to basket appearance" do
          visit "/about/baskets/appearance/#{@@about_basket.id}"
          body_should_contain "About Appearance"
        end

        should "not affect access to homepage options" do
          visit "/about/baskets/homepage_options/#{@@about_basket.id}"
          body_should_contain "About Homepage Options"
        end

        should "not affect access to member list" do
          visit "/about/members/list/#{@@about_basket.id}"
          body_should_contain "About Members"
        end

        should "not affect access to moderation list" do
          visit "/about/moderate/list/#{@@about_basket.id}"
          body_should_contain "Currently no items needing moderation."
        end

        if role == 'site_admin'
          should "not affect access to importer list" do
            visit "/about/importers/list"
            body_should_contain "This is the import facility."
          end
        end
      end
    end
  end
end
