require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  def setup
    @base_class = "Profile"
    @urlified_name = Basket.find(:first).urlified_name
  end

  include KeteTestFunctionalHelper

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

        Basket::FORMS_OPTIONS.each do |form_option|
          Profile.type_options.each do |type_option|
            should "be able to set form and type for #{form_option[0]} and #{type_option[0]}" do
              post :create, :urlified_name => @urlified_name, :profile => { :name => 'Test Profile',
                :rules => { form_option[1] => type_option[1] } }
            end
          end
        end
      end
    end
  end

  # should be able to create a profile with a specified form from Basket::FORMS_OPTIONS
  # that has a value from type_options
  #
  # new profile has area for each forms_options
  # with a field for type

  # the rest for now is handled by active scaffold
end
