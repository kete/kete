require File.dirname(__FILE__) + '/integration_test_helper'

class HistoryTest < ActionController::IntegrationTest
  ITEM_CLASSES.each do |item_class|
    context "The history page for a #{item_class}" do
      setup do
        add_admin_as_super_user
        add_dean_as_regular_user
        add_angela_as_regular_user
        add_rach_as_regular_user

        login_as('dean')
        @item =
          new_item({ :title => 'History Test v1' }, nil, nil, item_class) do
            fill_in_needed_information_for(item_class)
          end
        login_as('angela', 'test', { :logout_first => true })
        @item = update_item(@item, { :title => 'History Test v2' })

        login_as('rach', 'test', { :logout_first => true })
        @item = update_item(@item, { :title => 'History Test v3' })

        login_as('admin', 'test', { :logout_first => true })
      end

      should "show all versions and have correct contributors" do
        visit "/#{@item.basket.urlified_name}/#{zoom_class_controller(item_class)}/history/#{@item.id}"
        body_should_contain '# 1', :number_of_times => 1
        body_should_contain '>dean<', :number_of_times => 1
        body_should_contain '# 2', :number_of_times => 1
        body_should_contain '>angela<', :number_of_times => 1
        body_should_contain '# 3', :number_of_times => 1
        body_should_contain '>rach<', :number_of_times => 1
      end

      should "show the flags when they have them" do
        @item = flag_item_with(@item, :duplicate)
        @item = flag_item_with(@item, :inaccurate)

        visit "/#{@item.basket.urlified_name}/#{zoom_class_controller(item_class)}/history/#{@item.id}"
        body_should_contain 'duplicate', :number_of_times => 1
        body_should_contain 'inaccurate', :number_of_times => 1
      end
    end
  end

  private

  def old_login_as(username, password = 'test', options = {})
    options = { 
      :navigate_to_login => true,
      :should_fail_login => false 
    }.merge(options)
    if options[:navigate_to_login]
      logout # make sure we arn't logged in first
      visit "/site/account/login"
    end

    body_should_contain "Login to Kete"
    fill_in "login", :with => username.to_s
    fill_in "password", :with => password
    click_button "Login"

    body_should_contain("Logged in successfully") unless options[:should_fail_login]
  end
end
