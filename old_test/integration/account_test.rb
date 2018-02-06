# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest
  context "A User" do
    setup do
      add_paul_as_regular_user
    end

    should "be able to login" do
      login_as(
        'paul', 'test', { 
          :navigate_to_login => true,
          :by_form => true 
        }
      )
      body_should_contain "Logged in successfully"
      should_be_on_site_homepage
    end

    should "should have details displayed on the menu" do
      login_as(
        'paul', 'test', { 
          :navigate_to_login => true,
          :by_form => true 
        }
      )
      body_should_contain "paul"
      body_should_contain "Logout"
    end

    should "fail login with incorrect credentials" do
      login_as(
        'incorrect', 'login', { 
          :navigate_to_login => true,
          :by_form => true,
          :should_fail_login => true 
        }
      )
      body_should_contain "Your password or login do not match our records. Please try again."
    end

    should "be able to logout once logged in" do
      login_as('paul')
      body_should_contain "Logged in successfully"
      logout
      should_be_on_site_homepage
    end

    should "be redirected back to last tried location when logged in" do
      visit "/site/baskets/choose_type"
      login_as('paul', 'test', { :by_form => true })
      url_should_contain "/site/baskets/choose_type"
      body_should_contain "What would you like to add?"
    end

    context "when homepage slideshow controls are on" do
      setup do
        @@site_basket.update_attribute(:index_page_image_as, 'random')
        login_as('paul')
        @item1 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        @item2 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        @item3 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      teardown do
        @@site_basket.update_attribute(:index_page_image_as, '')
      end

      should "not have the slideshow override their return_to when logging in" do
        logout
        visit "/"
        visit "/site/account/login"
        login_as(
          'paul', 'test', { 
            :navigate_to_login => false,
            :by_form => true 
          }
        )
        url_should_contain Regexp.new("/$")
      end
    end

    context "when private items are enabled" do
      setup do
        @@site_basket.update_attribute(:show_privacy_controls, true)
        login_as('paul')
        @item =
          new_still_image({ 
                            :private_true => true,
                            :file_private_true => true 
                          }) { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      teardown do
        @@site_basket.update_attribute(:show_privacy_controls, false)
      end

      should "not have the private item override their return_to when logging in" do
        logout
        visit "/site/images/show/#{@item.to_param}"
        body_should_contain 'No Public Version Available'
        visit @item.original_file.public_filename.to_s
        body_should_contain 'Error 401: Unauthorized'
        visit "/site/account/login"
        login_as('paul', 'test', { :navigate_to_login => false, :by_form => true })
        url_should_contain "/site/images/show/#{@item.id}"
      end
    end
  end

  context "Login" do
    setup do
      @last_topic_in_site = @@site_basket.topics.last
      @last_topic_url = "/site/topics/show/#{@last_topic_in_site.to_param}"
    end

    context "when there are no allowed anonymous actions" do
      setup do
        logout
        configure_environment do
          set_constant('ALLOWED_ANONYMOUS_ACTIONS', "")
        end
      end

      should "not have option to be anonymous if visiting login page directly" do
        visit "/site/account/login"
        body_should_not_contain 'Your Email'
      end

      should "not have option to be anonymous if getting redirected to login page from link to comment" do
        visit @last_topic_url
        click_link "join this discussion"
        # redirected to login
        body_should_not_contain 'Your Email'
      end

      should "not have option to be anonymous if getting redirected to login page from link a contact form" do
        visit "/site/contact"
        # redirected to login
        body_should_not_contain 'Your Email'
      end
    end

    context "when coming from a redirect from a allowed_for anonymous action" do
      setup do
        logout
        configure_environment do
          set_constant(
            'ALLOWED_ANONYMOUS_ACTIONS',
            [{ :allowed_for => 'comments/new', :finished_after => 'comments/create' }, { :allowed_for => 'baskets/contact', :finished_after => 'baskets/send_email' }]
          )
        end
      end

      should "have opton to be anonymous for allowed_for action" do
        configure_environment do
          set_constant :CAPTCHA_TYPE, 'image'
        end

        visit @last_topic_url
        click_link I18n.t('application_helper.show_comments_for.join_discussion')
        # redirected to login
        # fill out anonymous part of form
        fill_in I18n.t('account.your_info.name'), :with => "Rodney Anonymous"
        fill_in I18n.t('account.your_info.email'), :with => "rodney@deadmilkmen.com"

        # check captcha is there, but can be skipped in test env
        body_should_contain I18n.t('account.captcha_wrapper.security_code')
        submit_form 'login'
      end

      should "have anonymous user email in session" do
      end

      should "not allow anonymous access to action accept for allowd_for and finished_after action" do
      end

      should "logout the anonymous user after finished_after action" do
      end
    end
  end

  private

  # current basket homepage is now the default redirect
  def should_be_on_site_homepage
    request_params = response.request.parameters
    assert_equal request_params[:action].to_s, 'index'
    assert_equal request_params[:controller].to_s, 'index_page'
    assert_equal request_params[:urlified_name].to_s, 'site'
  end
end
