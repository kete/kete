require File.dirname(__FILE__) + '/integration_test_helper'

# James - 2008-12-17
# This test is specifically geared to test for duplicate search record regression that has occured.

class DuplicateSearchRecordTest < ActionController::IntegrationTest
  context "A Kete instance" do
    setup do
      # Clean the zebra instance because we rely heavily on checking in this in tests.
      bootstrap_zebra_with_initial_records

      add_sarah_as_super_user
      login_as('sarah', 'test', { :logout_first => true })

      @new_basket = new_basket
      add_paul_as_member_to(@new_basket)
      User.find_by_login('paul').add_as_member_to_default_baskets

      login_as('paul', 'test', { :logout_first => true })
    end

    should "return no results because the zebra db is empty" do
      visit "/site/all/topics/"

      for name in ZOOM_CLASSES.map { |klass| zoom_class_plural_humanize(klass) }

        # Check that no records exist for each item type
        body_should_contain "#{name} (0)"

        # Check that no search results appear for each item type
        click_link "#{name} (0)"

        body_should_contain "Results in #{name.downcase}"
        body_should_contain I18n.t('search.results.no_results_of_any_type_found')

      end
    end

    should "only show one search result for a new topic" do
      topic = new_topic :title => "This is a new topic"
      should_appear_once_in_search_results(topic)
    end

    should_eventually "only show one search result for a new item of any type"

    should "only show one search result for a new topic when a related topic is created" do
      create_a_topic_with_a_related_topic
    end

    should "only show one search result when a related topic is edited, then the original topic is edited" do
      create_a_topic_with_a_related_topic

      update_item(@related_topic, :title => "Related topic with title changed")
      [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }

      update_item(@topic, :title => "Original topic with title changed")
      [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
    end

    should "only show one search result when a comment is added to a related topic" do
      [@@site_basket, @new_basket].each do |basket|
        login_as('sarah', 'test', { :logout_first => true })
        turn_off_full_moderation(basket)
        login_as('paul', 'test', { :logout_first => true })

        create_a_topic_with_a_related_topic(basket)

        update_item(@related_topic, :title => "Related topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }

        update_item(@topic, :title => "Original topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }

        visit "/#{basket.urlified_name}/topics/show/#{@related_topic.id}"

        click_link "join this discussion"
        fill_in "comment_title", :with => "This is a new comment!"
        fill_in "comment_description", :with => "Obviously this is a test."
        click_button "Save"

        body_should_contain "There are 1 comments in this discussion."
        body_should_contain Comment.last.title
        body_should_contain Comment.last.description, :number_of_times => 1

        update_item(@topic, :title => "Original topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
      end
    end

    should "only show one search result when a comment is added to a related topic with moderation" do
      [@@site_basket, @new_basket].each do |basket|
        login_as('sarah', 'test', { :logout_first => true })

        turn_on_full_moderation(basket)
        create_a_topic_with_a_related_topic(basket)

        # Right now this is failing to a moderation contribution email. See email from James 2008-12-18.
        login_as('paul', 'test', { :logout_first => true })
        update_item(@related_topic, :title => "Related topic with title changed")
        should_appear_once_in_search_results(@related_topic, :title => @related_topic.title)

        login_as('sarah', 'test', { :logout_first => true })
        @related_topic.reload
        moderate_restore(@related_topic, :version => 4)
        [@topic, @related_topic].each do |t|
          t.reload
          should_appear_once_in_search_results(t)
        end

        login_as('paul', 'test', { :logout_first => true })
        update_item(@topic, :title => "Original topic with title changed")
        should_appear_once_in_search_results(@topic, :title => @topic.title)

        login_as('sarah', 'test', { :logout_first => true })
        moderate_restore(@topic, :version => 4)

        [@topic, @related_topic].each do |t|
          t.reload
          should_appear_once_in_search_results(t)
        end

        visit "/#{basket.urlified_name}/topics/show/#{@related_topic.id}"

        click_link "join this discussion"
        fill_in "comment_title", :with => "This is a new comment!"
        fill_in "comment_description", :with => "Obviously this is a test."
        click_button "Save"

        body_should_contain "There are 1 comments in this discussion."
        body_should_contain Comment.last.title
        body_should_contain Comment.last.description, :number_of_times => 1

        login_as('paul', 'test', { :logout_first => true })
        update_item(@topic, :title => "Original topic with title changed again")
        should_appear_once_in_search_results(@topic, :title => "Original topic with title changed")

        login_as('sarah', 'test', { :logout_first => true })
        moderate_restore(@topic)
        [@topic, @related_topic].each do |t|
          t.reload
          should_appear_once_in_search_results(t)
        end
      end
    end

    teardown do
      ZOOM_CLASSES.each do |class_name|
        eval(class_name).destroy_all
      end
    end
  end

  context "a couple of related topics without moderation" do
    setup do
      add_robert_as_regular_user
      add_roberta_as_regular_user

      login_as("roberta", 'test', { :logout_first => true })

      create_a_topic_with_a_related_topic(@@site_basket, :member => 'roberta')
    end

    should "have appropriate search results initially" do
      [@topic, @related_topic].each do |t|
        should_appear_once_in_search_results(t)
      end
    end

    should "still have appropriate search results after numerous edits on each item" do
      update_and_check_search_results(@topic)
      should_appear_once_in_search_results(@related_topic)
      update_and_check_search_results(@related_topic)
      should_appear_once_in_search_results(@topic)
    end

    should "still have appropriate search results after numerous edits on each item with different users" do
      update_and_check_search_results(@topic)
      should_appear_once_in_search_results(@related_topic)

      login_as("robert", 'test', { :logout_first => true })

      update_and_check_search_results(@related_topic)
      should_appear_once_in_search_results(@topic)
    end
  end

  private

    def create_a_topic_with_a_related_topic(basket = @@site_basket, options = {})
      options = {
        :member => 'paul',
        :moderator => 'sarah'
      }.merge!(options)

      login_as(options[:member], 'test', { :logout_first => true }) if is_fully_moderated?(basket)

      @topic = new_topic({ :title => "A topic" }, basket)

      # Ensure that the topic has been moderated correctly.
      assert_equal(BLANK_TITLE, @topic.title, "Basket fully_moderated setting: " + basket.settings[:full_moderated].inspect) if is_fully_moderated?(basket)

      should_not_appear_in_search_results(@topic) if is_fully_moderated?(basket)

      if is_fully_moderated?(basket)
        login_as(options[:moderator], 'test', { :logout_first => true })
        moderate_restore(@topic, :version => 1)
      end

      @topic.reload
      should_appear_once_in_search_results(@topic)

      # Emulate clicking the "Create" link for related topics
      login_as(options[:member], 'test', { :logout_first => true }) if is_fully_moderated?(basket)

      @related_topic = new_item({ :new_path => "/#{basket.urlified_name}/topics/new?relate_to_item=#{@topic.id}&relate_to_type=Topic", :title => "A topic related to 'A topic'", :success_message => "Related Topic was successfully created." }, basket)

      should_not_appear_in_search_results(@related_topic) if is_fully_moderated?(basket)

      if is_fully_moderated?(basket)
        login_as(options[:moderator], 'test', { :logout_first => true })

        moderate_restore(@related_topic, :version => 1)
        @related_topic.reload
        assert_equal @related_topic.versions.find_by_version(1).title, @related_topic.title
      end

      visit "/#{basket.urlified_name}/topics/show/#{@topic.id}/"

      url = "http://www.example.com/#{basket.urlified_name}/topics/show/#{@related_topic.id}"
      body_should_contain "<a href=\"#{url}"

      should_appear_once_in_search_results(@topic)
      should_appear_once_in_search_results(@related_topic)
    end

    def update_and_check_search_results(item, title = "Changed items")
      update_item(item, :title => title)
      should_appear_once_in_search_results(item)
    end

    def is_fully_moderated?(basket)
      basket.settings[:fully_moderated].to_s == "true"
    end
end
