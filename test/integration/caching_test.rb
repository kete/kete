require File.dirname(__FILE__) + '/integration_test_helper'

require 'fileutils'

class CachingTest < ActionController::IntegrationTest

  context "The homepage cache" do

    setup do
      FileUtils.rm_rf(Dir["#{File.expand_path(File.dirname(__FILE__) + '/../../tmp/cache')}/[^.]*"])
      ActionController::Base.perform_caching = true
      ActionView::Base.cache_template_loading = true
      @@cache_basket ||= create_new_basket({ :name => 'Cache Basket' })
      @@cache_basket.index_page_link_to_index_topic_as = 'full topic and comments'
      @@cache_basket.save

      add_admin_as_super_user
      login_as('admin')
    end

    teardown do
      @@cache_basket.index_page_link_to_index_topic_as = nil
      @@cache_basket.save
      ActionController::Base.perform_caching = false
      ActionView::Base.cache_template_loading = false
      FileUtils.rm_rf(Dir["#{File.expand_path(File.dirname(__FILE__) + '/../../tmp/cache')}/[^.]*"])
    end

    context "when homepage topic is added" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 1 Title', 'Homepage 1 Description')
      end

      should "be populated with the new topic" do
        check_homepage_current(@topic)
      end

    end

    context "when homepage topic is replaced" do

      setup do
        @topic1 = new_item(@@cache_basket, 'Topic', true, 'Old Homepage Topic Title', 'Old Homepage Topic Description')
        check_homepage_current(@topic1)
        @topic2 = new_item(@@cache_basket, 'Topic', true, 'Homepage 2 Title', 'Homepage 2 Description')
      end

      should "be populated with the new topic" do
        check_homepage_current(@topic2)
        body_should_not_contain "Old Homepage Topic Title"
        body_should_not_contain "Old Homepage Topic Description"
      end

    end

    context "when homepage topic is updated" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 3 Title', 'Homepage 3 Description')
        check_homepage_current(@topic)
        @topic = update_item(@topic, 'Homepage 3 Updated Title', 'Homepage 3 Updated Description')
      end

      should "be populated with the new topic" do
        check_homepage_current(@topic)
        body_should_not_contain "Homepage 3 Title"
        body_should_not_contain "Homepage 3 Description"
      end

    end

    context "when homepage topic is deleted" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 4 Title', 'Homepage 4 Description')
        check_homepage_current(@topic)
        @topic = delete_item(@topic)
      end

      should "not contain traces of the old homepage" do
        visit "/cache_basket"
        body_should_not_contain "Homepage 4 Title"
        body_should_not_contain "Homepage 4 Description"
      end

    end

    context "when recent topics are enabled" do

      setup do
        @@cache_basket.index_page_number_of_recent_topics = 5
        @@cache_basket.index_page_recent_topics_as = 'headlines'
        @@cache_basket.save
      end

      teardown do
        @@cache_basket.index_page_number_of_recent_topics = 0
        @@cache_basket.index_page_recent_topics_as = nil
        @@cache_basket.save
      end

      context "and when the basket has a topic added" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Recent Topic 1 Title', 'Recent Topic 1 Description')
        end

        should "show up in the recent topic list" do
          check_recent_topics_include(@topic)
        end

      end

      context "and when the basket has a topic updated" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Recent Topic 2 Title', 'Recent Topic 2 Description')
          check_recent_topics_include(@topic)
          @topic = update_item(@topic, 'Recent Topic 2 Updated Title', 'Recent Topic 2 Updated Description')
        end

        should "be updated in the recent topic list" do
          check_recent_topics_include(@topic)
          body_should_not_contain "Recent Topic 2 Title"
          body_should_not_contain "Recent Topic 2 Description"
        end

      end

      context "and when the basket has a topic deleted" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Recent Topic 3 Title', 'Recent Topic 3 Description')
          check_recent_topics_include(@topic)
          @topic = delete_item(@topic)
        end

        should "be removed from the recent topic list" do
          visit "/cache_basket"
          body_should_not_contain "Recent Topic 3 Title"
          body_should_not_contain "Recent Topic 3 Description"
        end

      end

    end

    # Test cases past this point are not yet implemented

    context "when it has a private version" do

      should "cache seperate privacies" do
      end

      should "not be shown to the wrong users" do
      end

      context "and when basket has private as default privacy" do

        should "not show private homepage when not allowed" do
        end

        should "show the private homepage when allowed" do
        end

        should "not be shown to the wrong users" do
        end

      end

    end

  end

  private

  def check_homepage_current(item)
    controller = zoom_class_controller(item.class.name)
    visit "/#{item.basket.urlified_name}"
    #body_should_contain item.title
    body_should_contain item.description
    body_should_contain "/#{item.basket.urlified_name}/#{controller}/show/#{item.to_param}"
    body_should_contain "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}"
    body_should_contain "/#{item.basket.urlified_name}/#{controller}/history/#{item.to_param}"
  end

  def check_recent_topics_include(item)
    visit "/#{item.basket.urlified_name}"
    body_should_contain item.title
    body_should_contain item.description
  end

end
