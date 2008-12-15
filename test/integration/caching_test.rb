require File.dirname(__FILE__) + '/integration_test_helper'

class CachingTest < ActionController::IntegrationTest

  context "The homepage cache" do

    setup do
      enable_production_mode
      @@cache_basket ||= create_new_basket({ :name => 'Cache Basket' })
      @@cache_basket.index_page_link_to_index_topic_as = 'full topic and comments'
      @@cache_basket.save

      add_admin_as_super_user
      add_joe_as_member_to(@@cache_basket)
      add_john
      login_as('admin')
    end

    teardown do
      @@cache_basket.index_page_link_to_index_topic_as = nil
      @@cache_basket.save
      disable_production_mode
    end

    context "when homepage topic is added" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 1 Title', 'Homepage 1 Description')
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic)
      end

    end

    context "when homepage topic is replaced" do

      setup do
        @topic1 = new_item(@@cache_basket, 'Topic', true, 'Old Homepage Topic Title', 'Old Homepage Topic Description')
        check_cache_current_for(@topic1)
        @topic2 = new_item(@@cache_basket, 'Topic', true, 'Homepage 2 Title', 'Homepage 2 Description')
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic2)
        body_should_not_contain "Old Homepage Topic Title"
        body_should_not_contain "Old Homepage Topic Description"
      end

    end

    context "when homepage topic is updated" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 3 Title', 'Homepage 3 Description')
        check_cache_current_for(@topic)
        @topic = update_item(@topic, 'Homepage 3 Updated Title', 'Homepage 3 Updated Description')
      end

      should "be populated with the updated topic" do
        check_cache_current_for(@topic)
        body_should_not_contain "Homepage 3 Title"
        body_should_not_contain "Homepage 3 Description"
      end

    end

    context "when homepage topic is deleted" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', true, 'Homepage 4 Title', 'Homepage 4 Description')
        check_cache_current_for(@topic)
        @topic = delete_item(@topic)
      end

      should "not contain traces of the old homepage" do
        assert @topic.nil? # check the topic was deleted
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
          check_recent_topics_includes(@topic)
        end

      end

      context "and when the basket has a topic updated" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Recent Topic 2 Title', 'Recent Topic 2 Description')
          check_recent_topics_includes(@topic)
          @topic = update_item(@topic, 'Recent Topic 2 Updated Title', 'Recent Topic 2 Updated Description')
        end

        should "be updated in the recent topic list" do
          check_recent_topics_includes(@topic)
          body_should_not_contain "Recent Topic 2 Title"
          body_should_not_contain "Recent Topic 2 Description"
        end

      end

      context "and when the basket has a topic deleted" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Recent Topic 3 Title', 'Recent Topic 3 Description')
          check_recent_topics_includes(@topic)
          @topic = delete_item(@topic)
        end

        should "be removed from the recent topic list" do
          assert @topic.nil? # check the topic was deleted
          visit "/cache_basket"
          body_should_not_contain "Recent Topic 3 Title"
          body_should_not_contain "Recent Topic 3 Description"
        end

      end

    end

    context "when privacy controls are enabled" do

      setup do
        @@cache_basket.show_privacy_controls = true
        @@cache_basket.save
      end

      teardown do
        @@cache_basket.show_privacy_controls = false
        @@cache_basket.save
      end

      context "and when homepage has a private version" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', true, 'Public Title', 'Public Description') do |field_prefix|
            choose "#{field_prefix}_private_false"
          end
          check_cache_current_for(@topic)
          @topic = update_item(@topic, 'Private Title', 'Private Description') do |field_prefix|
            choose "#{field_prefix}_private_true"
          end
        end

        should "cache seperate privacies" do
          check_viewing_private_version_of(@topic)
        end

        should "not link to private version unless user has permission" do
          check_viewing_private_version_of(@topic) # as admin
          logout
          check_viewing_public_version_of(@topic, { :check_all_links => false })
          login_as('john')
          check_viewing_public_version_of(@topic, { :check_all_links => false })
          login_as('joe')
          check_viewing_private_version_of(@topic)
        end

        should "default to public version when non member tries to access private version" do
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_private_version_of(@topic, { :on_topic_already => true }) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_private_version_of(@topic, { :on_topic_already => true })
        end

        context "and when basket has private as default privacy" do

          setup do
            @@cache_basket.private_default = true
            @@cache_basket.save
          end

          teardown do
            @@cache_basket.private_default = false
            @@cache_basket.save
          end

          should "show private homepage automatically unless user is less than member" do
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_private_version_of(@topic, { :on_topic_already => true }) # as admin
            logout
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
            login_as('john')
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
            login_as('joe')
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_private_version_of(@topic, { :on_topic_already => true })
          end

        end

      end

    end

  end

  context "The topic show cache" do

    setup do
      enable_production_mode
      @@cache_basket ||= create_new_basket({ :name => 'Cache Basket' })
      add_admin_as_super_user
      add_joe_as_member_to(@@cache_basket)
      add_john
      login_as('admin')
    end

    teardown do
      disable_production_mode
    end

    context "when a topic is added" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', false, 'Topic 1 Title', 'Topic 1 Description')
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic, { :on_topic_already => true, :check_show_link => false })
      end

    end

    context "when a topic is updated" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', false, 'Topic 2 Title', 'Topic 2 Description')
        check_cache_current_for(@topic, { :on_topic_already => true, :check_show_link => false })
        @topic = update_item(@topic, 'Topic 2 Updated Title', 'Topic 2 Updated Description')
      end

      should "be populated with the updated topic" do
        check_cache_current_for(@topic, { :on_topic_already => true, :check_show_link => false })
        body_should_not_contain "Topic 2 Title"
        body_should_not_contain "Topic 2 Description"
      end

    end

    context "when a topic is deleted" do

      setup do
        @topic = new_item(@@cache_basket, 'Topic', false, 'Topic 3 Title', 'Topic 3 Description')
        check_cache_current_for(@topic, { :on_topic_already => true, :check_show_link => false })
        @old_topic = @topic
        @topic = delete_item(@topic)
      end

      should "not contain traces of the old topic" do
        assert @topic.nil? # check the topic was deleted
        controller = zoom_class_controller(@old_topic.class.name)
        visit "/#{@old_topic.basket.urlified_name}/#{controller}/show/#{@old_topic.id}"
        check_cache_current_for(@old_topic, { :on_topic_already => true, :check_should_not => true })
        body_should_not_contain "Topic 3 Title"
        body_should_not_contain "Topic 3 Description"
      end

    end

    context "when privacy controls are enabled" do

      setup do
        @@cache_basket.show_privacy_controls = true
        @@cache_basket.save
      end

      teardown do
        @@cache_basket.show_privacy_controls = false
        @@cache_basket.save
      end

      context "and when topic has a private version" do

        setup do
          @topic = new_item(@@cache_basket, 'Topic', false, 'Public Title', 'Public Description') do |field_prefix|
            choose "#{field_prefix}_private_false"
          end
          check_cache_current_for(@topic, { :on_topic_already => true, :check_show_link => false })
          @topic = update_item(@topic, 'Private Title', 'Private Description') do |field_prefix|
            choose "#{field_prefix}_private_true"
          end
        end

        should "cache seperate privacies" do
          check_viewing_private_version_of(@topic, { :on_topic_already => true, :check_show_link => false })
        end

        should "not link to private version unless user has permission" do
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_show_link => false }) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_show_link => false })
        end

        should "default to public version when non member tries to access private version" do
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_private_version_of(@topic, { :on_topic_already => true, :check_show_link => false }) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_public_version_of(@topic, { :on_topic_already => true, :check_all_links => false })
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_private_version_of(@topic, { :on_topic_already => true, :check_show_link => false })
        end

      end

    end

  end

  private

  def check_cache_current_for(item, args = {})
    visit "/#{item.basket.urlified_name}" unless args[:on_topic_already]
    contents = [item.description]
    contents << item.title if args[:check_page_title]
    controller = zoom_class_controller(item.class.name)
    contents << "/#{item.basket.urlified_name}/#{controller}/show/#{item.to_param}" if args[:check_show_link] || (args[:check_show_link].nil? && (args[:check_all_links].nil? || args[:check_all_links]))
    contents << "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}" if args[:check_edit_link] || (args[:check_edit_link].nil? && (args[:check_all_links].nil? || args[:check_all_links]))
    contents << "/#{item.basket.urlified_name}/#{controller}/history/#{item.to_param}" if args[:check_history_link] || (args[:check_history_link].nil? && (args[:check_all_links].nil? || args[:check_all_links]))
    contents.each do |content|
      args[:check_should_not] ? body_should_not_contain(content, nil, args[:debug_output]) :
                                body_should_contain(content, nil, args[:debug_output])
    end
  end

  def check_recent_topics_includes(item)
    visit "/#{item.basket.urlified_name}"
    body_should_contain item.title
    body_should_contain item.description
  end

  def check_viewing_public_version_of(item, args = {})
    unless args[:on_topic_already]
      visit "/#{item.basket.urlified_name}"
      body_should_not_contain "Private version"
      args[:on_topic_already] = true
    end
    check_cache_current_for(item, args)
    item.private_version! if item.has_private_version?
    check_cache_current_for(item, args.merge({ :check_should_not => true }))
    item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
  end

  def check_viewing_private_version_of(item, args = {})
    unless args[:on_topic_already]
      visit "/#{item.basket.urlified_name}"
      body_should_contain "Private version"
      click_link "Private Version"
      args[:on_topic_already] = true
    end
    check_cache_current_for(item, args.merge({ :check_should_not => true }))
    item.private_version! if item.has_private_version?
    check_cache_current_for(item, args)
    body_should_contain "Public version (live)"
    item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
  end

end
