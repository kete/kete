require File.dirname(__FILE__) + '/integration_test_helper'

class ModerationTest < ActionController::IntegrationTest
  context "a Kete instance" do

    setup do

      # Clean the zebra instance because we rely heavily on checking in this in tests.
      bootstrap_zebra_with_initial_records

      # Create a super-user account to perform moderator actions
      add_sarah_as_super_user
      login_as('sarah')

      # Add a new basket to test moderation in
      @basket = new_basket

      # Add a 'normal' member to the new basket
      add_paul_as_member_to(@basket)
      User.find_by_login('paul').add_as_member_to_default_baskets

      # Switch basket to the super-user to continue..
      login_as('sarah')
    end

    context "a fully moderated basket" do

      setup do
        turn_on_full_moderation(@basket)
        login_as('paul')
      end

      should "create a new item and have it moderated" do
        create_a_new_pending_topic_and_accept_it
      end

      should "update an item and have it moderated" do
        create_a_new_topic_with_several_approved_versions
      end

      should_eventually "revert to an earlier version" do
        create_a_new_topic_with_several_approved_versions
        # TODO: Add specific tests
      end

      should_eventually "create a new item and have it rejected"
      should_eventually "update an item and have it rejected"
      should_eventually "flag an accepted version of an item"
    end

    context "an open basket" do
      # TODO: Test flagging and moderation in an open basket
    end

    teardown do
      ZOOM_CLASSES.each do |class_name|
        eval(class_name).destroy_all
      end
    end

  end

  private

    # Some macros

    def create_a_new_pending_topic_and_accept_it

      # Create a new topic, which should be moderated since Paul is only a normal basket member.
      @topic = new_topic({ :title => "Test moderated topic" }, @basket)
      latest_version_should_be_pending(@topic)
      should_not_appear_in_search_results(@topic)

      # Login as a super-user and moderate (accept) the version.
      login_as('sarah')
      moderate_restore(@topic, :version => 1)

      @topic.reload
      latest_version_should_be_live(@topic)
      should_appear_once_in_search_results(@topic, :title => "Test moderated topic")
    end

    def create_a_new_topic_with_several_approved_versions
      create_a_new_pending_topic_and_accept_it

      login_as('paul')

      update_item(@topic, :title => "Title has been changed.")
      assert_equal @topic.versions.find_by_version(1).title, @topic.title
      should_appear_once_in_search_results(@topic, :title => @topic.versions.find_by_version(1).title)

      login_as('sarah')

      moderate_restore(@topic, :version => 4)

      @topic.reload
      latest_version_should_be_live(@topic)
      should_appear_once_in_search_results(@topic, :title => @topic.title)
    end

    # Some helpers below

    def latest_version_should_be_pending(item)
      assert item.versions.last.version != item.version || \
        item.title == BLANK_TITLE, "Current version should not be latest or be pending, but is not. #{item.inspect}"
    end

    def latest_version_should_be_live(item)
      assert_equal item.versions.last.title, item.title, "Current version should be the same as the latest, but is not."
      assert_not_equal item.title, BLANK_TITLE, "Current version should not have pending title, but does. #{item.inspect}"
    end

end