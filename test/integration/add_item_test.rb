require File.dirname(__FILE__) + '/integration_test_helper'

class AddItemTest < ActionController::IntegrationTest

  context "The add item functionality" do

    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    context "when Javascript is off" do

      ['Topic', 'Image', 'Audio', 'Video', 'Web Link', 'Document'].each do |item_type|
        should "still function properly for #{item_type}" do
          visit "/"
          click_link "Add Item"
          body_should_contain "What would you like to add? Where would you like to add it?"
          select "Site", :from => 'new_item_basket'
          select item_type, :from => 'new_item_controller'
          click_button "Choose"
          click_button "Choose Type" if item_type == 'Topic'
          body_should_contain "New #{item_type}"
        end
      end

    end

    # Needs Selenium testing available
    #context "when Javascript is on" do
    #  should "function without a page load" do
    #  end
    #end

  end

end