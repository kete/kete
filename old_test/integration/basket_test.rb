# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class BasketTest < ActionController::IntegrationTest
  context "When you view a basket that doesn't exist" do
    context "in production mode, it" do
      setup do
        enable_production_mode
        begin
          visit "/does_not_exist"
        rescue
        end
      end

      teardown do
        disable_production_mode
      end

      should "give a 404 (not blank page for error 500)" do
        body_should_contain "404 Error!"
      end
    end

    context "in development mode, it" do
      setup do
        begin
          visit "/does_not_exist"
        rescue
        end
      end

      should "give a backtrace with a meaningful raise" do
        body_should_contain "Couldn't find Basket with NAME=does_not_exist."
      end
    end
  end

  context "Full moderation in a basket" do
    setup do
      add_sarah_as_super_user
      login_as('sarah')

      @basket = new_basket
    end

    should "be able to be turned on" do
      @basket.settings[:fully_moderated] = false
      @basket.save!
      assert_equal "false", @basket.settings[:fully_moderated].to_s
      turn_on_full_moderation(@basket)
    end

    should "be able to be turned off" do
      @basket.settings[:fully_moderated] = true
      @basket.save!
      assert_equal "true", @basket.settings[:fully_moderated].to_s
      turn_off_full_moderation(@basket)
    end
  end

  context "When adding a new basket, it" do
    setup do
      add_sarah_as_super_user
      login_as('sarah')
      visit "/site/baskets/new"
    end

    should "require a name field" do
      click_button 'Create'
      body_should_contain '1 error prohibited this basket from being saved'
      body_should_contain 'Name can\'t be blank'
    end

    should "be successful when name field is filled in" do
      fill_in 'basket_name', :with => 'Kete Test Basket'
      click_button 'Create'
      body_should_contain 'Basket was successfully created.'
      body_should_contain 'Kete Test Basket Edit'
      @@baskets_created << Basket.last
    end
  end

  context "When editing a basket, it" do
    setup do
      @@edit_basket = create_new_basket({ :name => 'Edit Basket' })
      add_sarah_as_super_user
      login_as('sarah')
      visit "/#{@@edit_basket.urlified_name}/baskets/edit/#{@@edit_basket.to_param}"
    end

    should "require a name field" do
      fill_in 'basket_name', :with => ''
      click_button 'Update'
      body_should_contain '1 error prohibited this basket from being saved'
      body_should_contain 'Name can\'t be blank'
    end

    should "be succssful when name field is filled in" do
      fill_in 'basket_name', :with => 'Updated Kete Test Basket'
      click_button 'Update'
      body_should_contain 'Basket was successfully updated.'
      body_should_contain 'Updated Kete Test Basket'
    end
  end

  context "When deleting a basket, it" do
    setup do
      @@delete_basket ||= create_new_basket({ :name => 'Delete Basket' })
      add_sarah_as_super_user
      login_as('sarah')
    end

    should "be successful in its operation" do
      assert delete_basket(@@delete_basket)
    end
  end
end
