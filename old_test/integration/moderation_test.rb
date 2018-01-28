require File.dirname(__FILE__) + '/integration_test_helper'

class ModerationTest < ActionController::IntegrationTest
  context "a Kete instance" do
    setup do
      # Clean the zebra instance because we rely heavily on checking in this in tests.
      bootstrap_zebra_with_initial_records

      # Create a super-user account to perform moderator actions
      add_sarah_as_super_user
      login_as('sarah', 'test', { :logout_first => true })

      # Add a new basket to test moderation in
      @basket = new_basket

      # Add a 'normal' member to the new basket
      add_paul_as_member_to(@basket)
      User.find_by_login('paul').add_as_member_to_default_baskets

      # Switch basket to the super-user to continue..
      login_as('sarah', 'test', { :logout_first => true })
    end

    context "a fully moderated basket" do
      setup do
        turn_on_full_moderation(@basket)
        login_as('paul', 'test', { :logout_first => true })
      end

      should "create a new item and have it moderated" do
        create_a_new_pending_topic_and_accept_it
      end

      should "update an item and have it moderated" do
        create_a_new_topic_with_several_approved_versions
      end

      # should_eventually "revert to an earlier version" do
      #   create_a_new_topic_with_several_approved_versions
      #   # TODO: Add specific tests
      # end

      # should_eventually "create a new item and have it rejected"
      # should_eventually "update an item and have it rejected"
      # should_eventually "flag an accepted version of an item"
    end

    # context "an open basket" do
    #   # TODO: Test flagging and moderation in an open basket
    # end

    context "a topic with several revisions, one of which is invalid due to an additional extended field" do
      setup do
        @basket = new_basket :name => "Moderation test basket" do
          select 'moderator views before item approved', :from => 'settings_fully_moderated'
        end

        # Create a new topic type
        visit "/site/topic_types/new?parent_id=1"
        fill_in "Name", :with => "Topic type for moderation test"
        fill_in "Description", :with => "Topic type for moderation test description"
        click_button "Create"

        @topic_type = TopicType.last

        # Create a new topic of this topic type
        @topic = new_topic({ :title => "Initial version", :topic_type => "Topic type for moderation test" }, @basket)
        assert @topic.valid?

        # Add a required extended field to the topic type
        click_link "extended fields"
        click_link "Create New"

        fill_in "record_label_", :with => "Required field"
        select "Text", :from => "record_ftype"
        select "False", :from => "record_multiple"
        click_button "Create"

        assert_equal "Required field", ExtendedField.last.label
        @extended_field = ExtendedField.last

        visit "/site/topic_types/edit/#{@topic_type.id}"

        check "extended_field_#{@extended_field.to_param}_required_checkbox"
        click_button "Add to Topic Type"

        update_item @topic do
          fill_in "topic[extended_content_values][required_field]", :with => "Value for required field"
        end

        body_should_contain "Value for required field"
      end

      teardown do
        @topic_type.destroy rescue false
        @extended_field.destroy rescue false
      end

      should "be a fully moderated basket" do
        assert @basket.fully_moderated?
      end

      should "have an invalid earlier version" do
        @topic.revert_to(1)
        @topic.send(:allow_nil_values_for_extended_content=, false)
        assert !@topic.valid?
        @topic.send(:allow_nil_values_for_extended_content=, true)
        assert_equal true, @topic.send(:allow_nil_values_for_extended_content)
      end

      should "force content update when reverting to the first version" do
        visit "/#{@basket.urlified_name}/topics/preview/#{@topic.id}?version=1"
        click_link I18n.t('topics.preview_actions.make_live')
        body_should_contain "The version you're reverting to is missing some compulsory content. Please contribute the missing details before continuing. You may need to contact the original author to collect additional information."

        fill_in "topic[extended_content_values][required_field]", :with => "Value for required field after moderation"
        click_button "Update"
        body_should_contain "Topic was successfully updated."
        body_should_contain "Value for required field after moderation"
      end

      should "be able to add a new version and revert to the second without problem" do
        update_item(@topic, :title => "Third revision") do
          fill_in "topic[extended_content_values][required_field]", :with => "Value for required field"
        end

        visit "/#{@basket.urlified_name}/topics/preview/#{@topic.id}?version=2"
        click_link I18n.t('topics.preview_actions.make_live')

        body_should_contain "The content of this Topic has been approved from the selected revision."
        body_should_contain "Value for required field"
      end

      context "as a moderator" do
        setup do
          add_jenny_as_moderator_to(@basket)
          login_as('jenny', 'test', { :logout_first => true })
        end

        should "revert to first version, supply additional content and have version made live immediately" do
          visit "/#{@basket.urlified_name}/topics/preview/#{@topic.id}?version=1"
          click_link I18n.t('topics.preview_actions.make_live')

          body_should_contain "The version you're reverting to is missing some compulsory content. Please contribute the missing details before continuing. You may need to contact the original author to collect additional information."

          fill_in "topic[extended_content_values][required_field]", :with => "Moderator set value for required field after moderation"
          click_button "Update"

          body_should_contain "Topic was successfully updated."
          body_should_contain "Moderator set value for required field after moderation"

          @topic.reload
          assert_equal 3, @topic.version
        end

        should "be able to delete all versions of item from preview of version" do
          visit "/#{@basket.urlified_name}/topics/preview/#{@topic.id}?version=1"
          click_link I18n.t('topics.preview_actions.delete_all_versions')
          assert_equal "http://www.example.com/en/moderation_test_basket/all/topics/", current_url
        end
      end
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
    login_as('sarah', 'test', { :logout_first => true })
    moderate_restore(@topic, :version => 1)

    @topic.reload
    latest_version_should_be_live(@topic)
    should_appear_once_in_search_results(@topic, :title => @topic.title)
  end

  def create_a_new_topic_with_several_approved_versions
    create_a_new_pending_topic_and_accept_it

    login_as('paul', 'test', { :logout_first => true })

    update_item(@topic, :title => "Title has been changed.")
    assert_equal @topic.versions.find_by_version(1).title, @topic.title
    should_appear_once_in_search_results(@topic, :title => @topic.versions.find_by_version(1).title)

    login_as('sarah', 'test', { :logout_first => true })
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

  def configure_new_topic_type_with_extended_field(options = {})
    options = {
      :extended_field_value_required => false,
      :extended_field_label => "Extended data",
      :extended_field_multiple => false,
      :extended_field_ftype => "Text",
      :topic_type_name => "Test topic type",
      :topic_type_description => "Topic type description"
    }.merge(options)

    # Add a new extended field
    click_link "extended fields"
    click_link "Create New"

    fill_in "record_label_", :with => options[:extended_field_label]
    select options[:extended_field_ftype], :from => "record_ftype"
    select options[:extended_field_multiple].to_s.capitalize, :from => "record_multiple"
    click_button "Create"

    assert_equal options[:extended_field_label], ExtendedField.last.label
    @@extended_fields << ExtendedField.last

    visit "/site/topic_types/new?parent_id=1"
    fill_in "Name", :with => options[:topic_type_name]
    fill_in "Description", :with => options[:topic_type_description]
    click_button "Create"

    verb = options[:extended_field_value_required] ? "required" : "add"
    check "extended_field_#{ExtendedField.last.to_param}_#{verb}_checkbox"
    click_button "Add to Topic Type"

    text_verb = options[:extended_field_value_required] ? "required" : "optional"
    body_should_contain "#{options[:extended_field_label]} (#{text_verb})"

    assert_equal options[:topic_type_name], TopicType.last.name
    @@topic_types << TopicType.last

    return TopicType.last
  end
end
