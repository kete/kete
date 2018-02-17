require File.dirname(__FILE__) + '/integration_test_helper'

class CachingTest < ActionController::IntegrationTest
  context "The homepage cache" do
    setup do
      enable_production_mode
      @@cache_basket = create_new_basket(:name => 'Cache Basket')
      @@cache_basket.update_attribute(:index_page_link_to_index_topic_as, 'full topic and comments')

      add_admin_as_super_user
      add_joe_as_member_to(@@cache_basket)
      add_john
      login_as('admin')
    end

    teardown do
      @@cache_basket.update_attribute(:index_page_link_to_index_topic_as, nil)
      disable_production_mode
    end

    context "when homepage topic is added" do
      setup do
        @topic = new_homepage_topic(
          {
            :title => 'Homepage 1 Title',
            :description => 'Homepage 1 Description'
          }, @@cache_basket
        )
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic)
      end
    end

    context "when homepage topic is replaced" do
      setup do
        @topic1 = new_homepage_topic(
          {
            :title => 'Old Homepage Topic Title',
            :description => 'Old Homepage Topic Description'
          }, @@cache_basket
        )
        check_cache_current_for(@topic1)
        @topic2 = new_homepage_topic(
          {
            :title => 'Homepage 2 Title',
            :description => 'Homepage 2 Description'
          }, @@cache_basket
        )
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic2)
        body_should_not_contain "Old Homepage Topic Title"
        body_should_not_contain "Old Homepage Topic Description"
      end
    end

    context "when homepage topic is updated" do
      setup do
        @topic = new_homepage_topic(
          {
            :title => 'Homepage 3 Title',
            :description => 'Homepage 3 Description'
          }, @@cache_basket
        )
        check_cache_current_for(@topic)
        @topic = update_item(
          @topic, 
            :title => 'Homepage 3 Updated Title',
            :description => 'Homepage 3 Updated Description'
        )
      end

      should "be populated with the updated topic" do
        check_cache_current_for(@topic)
        body_should_not_contain "Homepage 3 Title"
        body_should_not_contain "Homepage 3 Description"
      end
    end

    context "when homepage topic is deleted" do
      setup do
        @topic = new_homepage_topic(
          {
            :title => 'Homepage 4 Title',
            :description => 'Homepage 4 Description'
          }, @@cache_basket
        )
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
        @@cache_basket.update_attributes(
                                           :index_page_number_of_recent_topics => 5,
                                           :index_page_recent_topics_as => 'headlines'
                                         )
      end

      teardown do
        @@cache_basket.update_attributes(
                                           :index_page_number_of_recent_topics => 0,
                                           :index_page_recent_topics_as => nil
                                         )
      end

      context "and when the basket has a topic added" do
        setup do
          @topic = new_topic(
            {
              :title => 'Recent Topic 1 Title',
              :description => 'Recent Topic 1 Description'
            }, @@cache_basket
          )
        end

        should "show up in the recent topic list" do
          check_recent_topics_includes(@topic)
        end
      end

      context "and when the basket has a topic updated" do
        setup do
          @topic = new_topic(
            {
              :title => 'Recent Topic 2 Title',
              :description => 'Recent Topic 2 Description'
            }, @@cache_basket
          )
          check_recent_topics_includes(@topic)
          @topic = update_item(
            @topic, 
              :title => 'Recent Topic 2 Updated Title',
              :description => 'Recent Topic 2 Updated Description'
          )
        end

        should "be updated in the recent topic list" do
          check_recent_topics_includes(@topic)
          body_should_not_contain "Recent Topic 2 Title"
          body_should_not_contain "Recent Topic 2 Description"
        end
      end

      context "and when the basket has a topic deleted" do
        setup do
          @topic = new_topic(
            {
              :title => 'Recent Topic 3 Title',
              :description => 'Recent Topic 3 Description'
            }, @@cache_basket
          )
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
        @@cache_basket.update_attribute(:show_privacy_controls, true)
      end

      teardown do
        @@cache_basket.update_attribute(:show_privacy_controls, false)
      end

      context "and when homepage has a private version" do
        setup do
          @topic = new_homepage_topic(
            {
              :title => 'Public Title',
              :description => 'Public Description',
              :private_false => true
            }, @@cache_basket
          )
          check_cache_current_for(@topic)
          @topic = update_item(
            @topic, 
              :title => 'Private Title',
              :description => 'Private Description',
              :private_true => true
          )
        end

        should "cache seperate privacies" do
          check_viewing_private_version_of(@topic)
        end

        should "not link to private version unless user has permission" do
          check_viewing_private_version_of(@topic) # as admin
          logout
          check_viewing_public_version_of(@topic, :check_all_links => false)
          login_as('john')
          check_viewing_public_version_of(@topic, :check_all_links => false)
          login_as('joe')
          check_viewing_private_version_of(
            @topic, 
              :check_all_links => false,
              :check_show_link => true
          )
        end

        should "default to public version when non member tries to access private version" do
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_private_version_of(@topic,  :on_topic_already => true ) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_viewing_private_version_of(
            @topic, 
              :on_topic_already => true,
              :check_all_links => false,
              :check_show_link => true
          )
        end

        context "and when basket has private as default privacy" do
          setup do
            @@cache_basket.update_attribute(:private_default, true)
          end

          teardown do
            @@cache_basket.update_attribute(:private_default, false)
          end

          should "show private homepage automatically unless user is less than member" do
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_private_version_of(@topic,  :on_topic_already => true ) # as admin
            logout
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
            login_as('john')
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
            login_as('joe')
            visit "/#{@topic.basket.urlified_name}"
            check_viewing_private_version_of(
              @topic, 
                :on_topic_already => true,
                :check_all_links => false,
                :check_show_link => true
            )
          end
        end
      end
    end
  end

  context "The topic show cache" do
    setup do
      enable_production_mode
      @@cache_basket = create_new_basket(:name => 'Cache Basket')
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
        @topic = new_topic(
          {
            :title => 'Topic 1 Title',
            :description => 'Topic 1 Description'
          }, @@cache_basket
        )
      end

      should "be populated with the new topic" do
        check_cache_current_for(@topic, :on_topic_already => true, :check_show_link => false)
      end
    end

    context "when a topic is updated" do
      setup do
        @topic = new_topic(
          {
            :title => 'Topic 2 Title',
            :description => 'Topic 2 Description'
          }, @@cache_basket
        )
        check_cache_current_for(@topic, :on_topic_already => true, :check_show_link => false)
        @topic = update_item(
          @topic, 
            :title => 'Topic 2 Updated Title',
            :description => 'Topic 2 Updated Description'
        )
      end

      should "be populated with the updated topic" do
        # NOTE: this will fail if you are running only this file's tests
        # and the test from with test directory
        # cd .. and run tests again
        check_cache_current_for(@topic, :on_topic_already => true, :check_show_link => false)
        body_should_not_contain "Topic 2 Title"
        body_should_not_contain "Topic 2 Description"
      end
    end

    context "when a topic is deleted" do
      setup do
        @topic = new_topic(
          {
            :title => 'Topic 3 Title',
            :description => 'Topic 3 Description'
          }, @@cache_basket
        )
        check_cache_current_for(@topic, :on_topic_already => true, :check_show_link => false)
        controller = zoom_class_controller(@topic.class.name)
        @topic_url = "/#{@topic.basket.urlified_name}/#{controller}/show/#{@topic.id}"
        @topic = delete_item(@topic)
      end

      should "not contain traces of the old topic" do
        assert @topic.nil? # check the topic was deleted
        visit @topic_url
        # we should get a 404 back for this page
        assert !response.ok?
      end
    end

    context "when privacy controls are enabled" do
      setup do
        @@cache_basket.update_attribute(:show_privacy_controls, true)
      end

      teardown do
        @@cache_basket.update_attribute(:show_privacy_controls, false)
      end

      context "and when topic has a private version" do
        setup do
          @topic = new_topic(
            {
              :title => 'Public Title',
              :description => 'Public Description',
              :private_false => true
            }, @@cache_basket
          )
          check_cache_current_for(@topic, :on_topic_already => true, :check_show_link => false)
          @topic = update_item(
            @topic, 
              :title => 'Private Title',
              :description => 'Private Description',
              :private_true => true
          )
        end

        should "cache seperate privacies" do
          check_viewing_private_version_of(@topic, :on_topic_already => true, :check_show_link => false)
        end

        should "not link to private version unless user has permission" do
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic,  :on_topic_already => true, :check_show_link => false ) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_show_link => false)
        end

        should "default to public version when non member tries to access private version" do
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_private_version_of(@topic,  :on_topic_already => true, :check_show_link => false ) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_all_links => false)
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.to_param}?private=true"
          check_viewing_private_version_of(@topic, :on_topic_already => true, :check_show_link => false)
        end
      end

      context "and a topic has both a public and private version, with revisions, it" do
        setup do
          @topic = new_topic(
            {
              :title => 'Public Title',
              :description => 'Public Description',
              :private_false => true
            }, @@cache_basket
          )
          @topic = update_item(
            @topic, 
              :title => 'Public SPAM',
              :description => 'Public SPAM',
              :private_false => true
          )
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_show_link => false)
          @topic = update_item(
            @topic, 
              :title => 'Private Title',
              :description => 'Private Description',
              :private_true => true
          )
          @topic.private_version!
          @topic = update_item(
            @topic, 
              :title => 'Private SPAM',
              :description => 'Private SPAM',
              :private_true => true
          )
          check_viewing_private_version_of(@topic, :on_topic_already => true, :check_show_link => false)
          @topic.public_version!
        end

        should "clear the cache for the correct privacy when a previous revision is made live" do
          # public cache
          @topic = moderate_restore(@topic, :version => 1)
          check_viewing_public_version_of(@topic, :on_topic_already => true, :check_show_link => false)

          # private cache
          @topic = moderate_restore(@topic, :version => 3)
          check_viewing_private_version_of(@topic, :on_topic_already => true, :check_show_link => false)
        end
      end
    end
  end

  private

  def check_cache_current_for(item, options = {})
    visit "/#{item.basket.urlified_name}" unless options[:on_topic_already]
    contents = [item.description]
    contents << item.title if options[:check_page_title]
    controller = zoom_class_controller(item.class.name)
    contents << "/#{item.basket.urlified_name}/#{controller}/show/#{item.to_param}" if options[:check_show_link] || (options[:check_show_link].nil? && (options[:check_all_links].nil? || options[:check_all_links]))
    contents << "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}" if options[:check_edit_link] || (options[:check_edit_link].nil? && (options[:check_all_links].nil? || options[:check_all_links]))
    contents << "/#{item.basket.urlified_name}/#{controller}/history/#{item.to_param}" if options[:check_history_link] || (options[:check_history_link].nil? && (options[:check_all_links].nil? || options[:check_all_links]))
    contents.each do |content|
      options[:check_should_not] ? body_should_not_contain(content, options) :
                                   body_should_contain(content, options)
    end
  end

  def check_recent_topics_includes(item)
    visit "/#{item.basket.urlified_name}"
    body_should_contain item.title
    body_should_contain item.description
  end

  def check_viewing_public_version_of(item, options = {})
    unless options[:on_topic_already]
      visit "/#{item.basket.urlified_name}"
      body_should_not_contain "Private version" unless item.has_private_version?
      options[:on_topic_already] = true
    end
    check_cache_current_for(item, options)
    if item.has_private_version?
      item.private_version!
      check_cache_current_for(item, options.merge(:check_should_not => true))
      item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
    end
  end

  def check_viewing_private_version_of(item, options = {})
    raise "ERROR: #{item.class.name} does not have a private version." unless item.has_private_version?
    unless options[:on_topic_already]
      visit "/#{item.basket.urlified_name}"
      body_should_contain "Private version"
      click_link "Private Version"
      options[:on_topic_already] = true
    end
    check_cache_current_for(item, options.merge(:check_should_not => true))
    item.private_version! if item.has_private_version?
    check_cache_current_for(item, options)
    body_should_contain "Public version (live)"
    item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
  end
end
