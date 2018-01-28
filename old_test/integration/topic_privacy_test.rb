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

    context "when privacy controls are enabled" do
      setup do
        @@site_basket.update_attribute(:show_privacy_controls, true)
      end

      should "create a public topic" do
        new_topic do
          fill_in "topic[title]", :with => "Test Topic"
          fill_in "topic[short_summary]", :with => "A test summary"
          fill_in "topic[description]", :with => "A test description"
        end

        body_should_contain("Topic was successfully created.")
        body_should_contain("Test Topic")
        body_should_contain("view-link")

        # TODO: Update test to conform to new editor details
        # body_should_contain("Created by:")
        body_should_not_contain("Private version")
      end

      should "create a private topic" do
        new_topic do
          choose "Private"
          fill_in "topic[title]", :with => "Test Topic"
          fill_in "topic[short_summary]", :with => "A test summary"
          fill_in "topic[description]", :with => "A test description"
        end

        body_should_contain("Topic was successfully created.")
        body_should_contain("Test Topic")
        body_should_contain("A test description")
        body_should_contain("Public version (live)")

        click_link "Public version (live)"

        body_should_contain (NO_PUBLIC_VERSION_TITLE).to_s
        body_should_contain NO_PUBLIC_VERSION_DESCRIPTION
        body_should_contain "Private version"

        click_link "Private version"

        body_should_contain("Test Topic")
        body_should_contain("A test description")
        body_should_contain("Public version (live)")
      end
    end

    context 'with private baskets and items of various privacies' do
      setup do
        @first_basket   = new_basket({ :name => "First basket",
                                       :show_privacy_controls_true => true })
        @second_basket  = new_basket({ :name => "Second basket",
                                       :show_privacy_controls_true => true })

        add_laura_as_super_user
        login_as('laura')

        @private_topic = new_topic({ :title => 'Mixed topic (public)' }, @first_basket)

        update_item(@private_topic) do
          choose 'Private'
          fill_in 'topic[title]', :with => 'Mixed topic (private)'
        end

        body_should_contain 'Public version (live)'
      end

      should "be able to move a private item to another basket" do
        update_item(@private_topic, :edit_path => "#{@first_basket.urlified_name}/topics/edit/#{@private_topic.id}?private=true") do
          select @second_basket.name, :from => "topic_basket_id"
        end

        # Perform a reload to ensure we have the public version of the item
        @private_topic.reload

        should_not_be_private @private_topic
        assert_equal @second_basket, @private_topic.basket

        @private_topic.private_version do
          should_be_private @private_topic
          assert_equal @second_basket, @private_topic.basket
        end
      end

      should "be able to move the public version of an item to another basket" do
        assert_equal @first_basket, @private_topic.basket

        update_item(@private_topic) do
          select @second_basket.name, :from => "topic_basket_id"
        end

        @private_topic.reload

        should_not_be_private @private_topic
        assert_equal @second_basket, @private_topic.basket

        @private_topic.private_version do
          should_be_private @private_topic
          assert_equal @second_basket, @private_topic.basket
        end
      end
    end
  end

  private

  def should_be_private(item)
    assert item.private?, "#{item.class.name} instance expected to be private, but was not:  #{item.inspect}."
  end

  def should_not_be_private(item)
    assert !item.private?, "#{item.class.name} instance expected not to be private, but it was:  #{item.inspect}."
  end
end
