require File.dirname(__FILE__) + '/integration_test_helper'

class TopicPrivacyTest < ActionController::IntegrationTest

  context "A Kete instance" do

    setup do

      # Allow anyone to create baskets for the purposes of this test
      configure_environment do
        set_constant :BASKET_CREATION_POLICY, "open"
      end

      # Ensure a user account to log in with is present
      add_joe_as_super_user
      login_as('joe')
    end

    should "have open basket creation policy" do
      assert_equal "open", BASKET_CREATION_POLICY
    end

    context "when privacy controls are enabled" do

      setup do
        @@site_basket.update_attribute(:show_privacy_controls, true)
      end

      should "create a public topic" do
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
    
    context 'with private baskets and items of various privacies' do

      setup do
        @first_basket   = new_basket("First basket", true)
        @second_basket  = new_basket("Second basket", true)
        
        @private_topic  = new_item(@first_basket, 'Topic', false, 'Mixed topic (public)')
        # @mixed_topic    = new_item(@first_basket, 'Topic', false, 'Mixed topic (public)')
        
        on_edit_topic_form(@private_topic) do
          choose 'Private'
          fill_in 'topic[title]', :with => 'Mixed topic (private)'
        end
      
        body_should_contain 'Public version (live)'
      end
      
      should "be able to move a private item to another basket" do
        on_edit_topic_form(@private_topic, "#{@first_basket.urlified_name}/topics/edit/#{@private_topic.id}?private=true") do
          select @second_basket.name, :from => "topic_basket_id"
        end
        
        # Perform a reload to ensure we have the public version of the item
        @private_topic.reload
        
        assert !@private_topic.private?
        assert_equal @second_basket, @private_topic.basket
        
        @private_topic.private_version do
          assert_private_version @private_topic
          assert_equal @second_basket, @private_topic.basket
        end
      end
      
      should "be able to move the public version of an item to another basket" do
        assert_equal @first_basket, @private_topic.basket
        
        on_edit_topic_form(@private_topic) do
          select @second_basket.name, :from => "topic_basket_id"
        end
        
        @private_topic.reload
        
        assert !@private_topic.private?
        assert_equal @second_basket, @private_topic.basket
        
        @private_topic.private_version do
          assert @private_topic.private?
          assert_equal @second_basket, @private_topic.basket
        end
      end
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
    
    
    def on_edit_topic_form(topic, edit_path = nil, &block)
      raise "Please pass a block with topic form actions" unless block_given?
      
      path = edit_path || "/#{topic.basket.urlified_name}/topics/edit/#{topic.id}"
      visit path
      
      body_should_contain "Editing Topic"
      
      yield(block)
      
      click_button "Update"
      body_should_contain "Topic was successfully edited."
    end
    
    def assert_private_version(item)
      assert item.private?, "#{item.class.name} instance expected to be private, but was not:  #{item.inspect}."
    end

end