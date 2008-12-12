require File.dirname(__FILE__) + '/integration_test_helper'

require 'fileutils'

class CachingTest < ActionController::IntegrationTest

  context "The homepage cache" do

    setup do
      # emulate the tmp:cache:clear task
      FileUtils.rm_rf(Dir["#{File.expand_path(File.dirname(__FILE__) + '/../../tmp/cache')}/[^.]*"])
      # enable class caching
      ActionController::Base.perform_caching = true
      # enable template caching
      ActionView::Base.cache_template_loading = true
      # create a basket we'll be using for these tests
      @@cache_basket ||= create_new_basket({ :name => 'Cache Basket' })
      @@cache_basket.index_page_link_to_index_topic_as = 'full topic and comments'
      @@cache_basket.index_page_number_of_recent_topics = 5
      @@cache_basket.index_page_recent_topics_as = 'headlines'
      add_admin_as_super_user
      login_as('admin')
    end

    context "when homepage topic is added" do
      setup do
        @topic = new_item(@@cache_basket, 'Topic', true)
      end
      should "be populated with the new topic" do
        check_homepage_current(@topic)
      end
    end

    context "when homepage topic is replaced" do
      setup do
        @topic1 = new_item(@@cache_basket, 'Topic', true, 'Topic One Title', 'Topic One Description')
        check_homepage_current(@topic1)
        @topic2 = new_item(@@cache_basket, 'Topic', true, 'Topic Two Title', 'Topic Two Description')
      end
      should "be populated with the new topic" do
        check_homepage_current(@topic2)
        body_should_not_contain "Topic One Title"
        body_should_not_contain "Topic One Description"
      end
    end

    context "when homepage topic is updated" do
      setup do
        @topic = new_item(@@cache_basket, 'Topic', true)
        @topic = update_item(@topic)
      end
      should "be populated with the new topic" do
        check_homepage_current(@topic)
      end
    end

    context "when homepage topic is deleted" do
      setup do
        @topic = new_item(@@cache_basket, 'Topic', true)
        @topic = delete_item(@topic)
      end
      should "not contain traces of the old homepage" do
        visit "/cache_basket"
        body_should_not_contain "Homepage Title"
        body_should_not_contain "Homepage Description"
      end
    end

    # Test cases past this point are not yet implemented

    context "when the basket has a topic updated" do
      should "clear recent results cache" do
      end
    end

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

end
