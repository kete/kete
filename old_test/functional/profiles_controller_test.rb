# frozen_string_literal: true

require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper
  def setup
    @base_class = "Profile"
    @urlified_name = Basket.find(:first).urlified_name
  end

  context "The profiles controller" do
    # test that you must be logged in to access list
    should "test that you must be logged in to access list action" do
      assert_requires_login do |c|
        c.get :list, :urlified_name => @urlified_name
      end
    end

    # test that only site admins can do anything
    context "when a logged in user accesses an action, the user" do
      should "be given access if they are a site admin" do
        login_as :admin
        get :list, :urlified_name => @urlified_name
        assert_response :success
      end

      should "be denied access if they are not a site admin" do
        create_new_user(:login => 'plain_jane')
        login_as @user.login
        get :list, :urlified_name => @urlified_name
        assert_response :redirect
      end

      context "can use the new form and" do
        setup do
          login_as :admin
        end

        Basket.forms_options.each do |form_option|
          Profile.type_options.each do |type_option|
            should "be able to set form and type for #{form_option[0]} and #{type_option[0]}" do
              post :create, :urlified_name => @urlified_name, :record => { 
                :name => 'Test Profile',
                :rules => { form_option[1] => { 'rule_type' => type_option[1] } } 
              }
            end
          end
        end

        should "be able to create a record" do
          create_profile
        end

        should "not be able to edit a record" do
          create_profile
          assert_raise ActiveScaffold::ActionNotAllowed do
            post :update, :urlified_name => @urlified_name, :id => @profile, :record => { :name => 'Updated Title' }
          end
          @profile.reload
          assert @profile.name != 'Updated Title'
        end

        should "be able to delete a record without mappings" do
          create_profile
          post :destroy, :urlified_name => @urlified_name, :id => @profile
          assert_raise ActiveRecord::RecordNotFound do
            @profile.reload
          end
        end

        should "not be able to delete a record with mappings" do
          create_profile
          basket = Factory(:basket)
          basket.profiles << @profile
          @profile.reload
          assert_raise ActiveScaffold::RecordNotAllowed do
            post :destroy, :urlified_name => @urlified_name, :id => @profile
          end
        end
      end
    end
  end

  private

  def create_profile
    random = rand
    post :create, :urlified_name => @urlified_name,
                  :record => {
                    :name => "Test Profile #{random}",
                    :rules => {
                      Basket.forms_options[0][1] => { 'rule_type' => Profile.type_options[0][1] },
                      Basket.forms_options[1][1] => { 'rule_type' => Profile.type_options[1][1] },
                      Basket.forms_options[2][1] => { 'rule_type' => Profile.type_options[2][1] }
                    }
                  }
    assert_response :redirect
    @profile = Profile.last
    assert_equal @profile.name, "Test Profile #{random}"
  end

  # the rest for now is handled by active scaffold
end
