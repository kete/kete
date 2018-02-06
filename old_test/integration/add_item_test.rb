# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class AddItemTest < ActionController::IntegrationTest
  context "The add item functionality" do
    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    context "as admin, when Javascript is off" do
      # TODO: this doesn't actually complete the process
      # it just tests the form
      # we should probably add tests for bad data (missing title) that should receive validation error
      # and actual successful submission of items
      # obviously there will need to be work with temp files for uploads
      # this is probably the reason this is skipped, since this may be trickier with webrat
      ITEM_CLASSES.each do |item_class|
        should "still function properly for #{item_class}" do
          item_type = zoom_class_humanize(item_class)
          visit "/site/baskets/choose_type"
          body_should_contain "What would you like to add? Where would you like to add it?"
          select "Site", :from => 'new_item_basket'
          select item_type, :from => 'new_item_controller'
          click_button "Choose"
          click_button "Choose Type" if item_type == 'Topic'
          body_should_contain "New #{item_type}"
        end
      end
    end

    setup do
      add_paul_as_regular_user
      login_as('paul')
    end

    context "as a normal user, when Javascript is off" do
      # TODO: this doesn't actually complete the process
      # it just tests the form
      # we should probably add tests for bad data (missing title) that should receive validation error
      # and actual successful submission of items
      # obviously there will need to be work with temp files for uploads
      # this is probably the reason this is skipped, since this may be trickier with webrat
      ITEM_CLASSES.each do |item_class|
        should "still function properly for #{item_class}" do
          item_type = zoom_class_humanize(item_class)
          visit "/site/baskets/choose_type"
          body_should_contain "What would you like to add?"
          select "Site", :from => 'new_item_basket'
          select item_type, :from => 'new_item_controller'
          click_button "Choose"
          click_button "Choose Type" if item_type == 'Topic'
          body_should_contain "New #{item_type}"
        end
      end
    end
  end
end
