require File.dirname(__FILE__) + '/integration_test_helper'

class TopicPrivacyTest < ActionController::IntegrationTest
  context "A Kete instance" do

    setup do

      # Allow anyone to create baskets for the purposes of this test
      configure_environment do
        set_constant :BASKET_CREATION_POLICY, "open"
      end

      # Ensure a user account to log in with is present
      add_joe_as_regular_user
      login_as('joe')
    end

    should "have open basket creation policy" do
      assert_equal "open", BASKET_CREATION_POLICY
    end

    should "create a public topic" do
      Basket.find(1).update_attribute(:show_privacy_controls, true)

      on_create_topic_form do

        fill_in "topic[title]", :with => "Test Topic"
        fill_in "topic[short_summary]", :with => "A test summary"
        fill_in "topic[description]", :with => "A test description"

      end

      body_should_contain("Topic was successfully created.")
      body_should_contain("Topic: Test Topic")
      body_should_contain("view-link")
      body_should_contain("Created by:")
      body_should_not_contain("Private version")
    end

    should "create a private topic" do
      Basket.find(1).update_attribute(:show_privacy_controls, true)

      on_create_topic_form do

        choose "Private"
        fill_in "topic[title]", :with => "Test Topic"
        fill_in "topic[short_summary]", :with => "A test summary"
        fill_in "topic[description]", :with => "A test description"

      end

      body_should_contain("Topic was successfully created.")
      body_should_contain("Topic: Test Topic")
      body_should_contain("A test description")
      body_should_contain("Public version (live)")

      click_link "Public version (live)"

      body_should_contain "Topic: #{NO_PUBLIC_VERSION_TITLE}"
      body_should_contain NO_PUBLIC_VERSION_DESCRIPTION
      body_should_contain "Private version"

      click_link "Private version"

      body_should_contain("Topic: Test Topic")
      body_should_contain("A test description")
      body_should_contain("Public version (live)")

    end

  end

  private

    def on_create_topic_form(&block)
      raise "Please pass a block with topic form actions" unless block_given?

      visit "/site/baskets/choose_type"

      body_should_contain "What would you like to add?"

      select "Topic", :from => "new_item_controller"
      click_button "Choose"

      select "Topic", :from => "topic[topic_type_id]"
      click_button "Choose"

      body_should_contain "New Topic"
      body_should_contain "Title"

      # Here you give instructions to the topic creation form
      yield(block)

      click_button "Create"
    end

end