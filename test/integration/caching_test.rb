require File.dirname(__FILE__) + '/integration_test_helper'

class CachingTest < ActionController::IntegrationTest

  context "The homepage cache" do

    setup do
      enable_caching
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
      disable_caching
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
          check_homepage_current(@topic)
          @topic = update_item(@topic, 'Private Title', 'Private Description') do |field_prefix|
            choose "#{field_prefix}_private_true"
          end
        end

        should "cache seperate privacies" do
          check_private_version_viewable(@topic)
        end

        should "not link to private version unless user has permission" do
          check_private_version_viewable(@topic) # as admin
          logout
          check_private_version_not_viewable(@topic, { :check_edit_links => false })
          login_as('john')
          check_private_version_not_viewable(@topic, { :check_edit_links => false })
          login_as('joe')
          check_private_version_viewable(@topic)
        end

        should "default to public version when non member tries to access private version" do
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_private_version_viewable(@topic, { :on_private_homepage_already => true }) # as admin
          logout
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_private_version_not_viewable(@topic, { :on_private_homepage_already => true,
                                                       :check_edit_links => false })
          login_as('john')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_private_version_not_viewable(@topic, { :on_private_homepage_already => true,
                                                       :check_edit_links => false })
          login_as('joe')
          visit "/#{@topic.basket.urlified_name}/index_page?private=true"
          check_private_version_viewable(@topic, { :on_private_homepage_already => true })
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
            check_private_version_viewable(@topic, { :on_private_homepage_already => true }) # as admin
            logout
            visit "/#{@topic.basket.urlified_name}"
            check_private_version_not_viewable(@topic, { :on_private_homepage_already => true,
                                                         :check_edit_links => false })
            login_as('john')
            visit "/#{@topic.basket.urlified_name}"
            check_private_version_not_viewable(@topic, { :on_private_homepage_already => true,
                                                         :check_edit_links => false })
            login_as('joe')
            visit "/#{@topic.basket.urlified_name}"
            check_private_version_viewable(@topic, { :on_private_homepage_already => true })
          end

        end

      end

    end

  end

  private

  def check_homepage_current(item, args = {})
    # I tried args[:check_edit_links] || true
    # But it looks like Ruby assigns it true if the args is false (as well as nil)
    # So we have to do a ternary operator to assign it instead
    on_homepage_already = !args[:on_homepage_already].nil? ? args[:on_homepage_already] : false
    check_edit_links = !args[:check_edit_links].nil? ? args[:check_edit_links] : true
    check_should_not = !args[:check_should_not].nil? ? args[:check_should_not] : false
    controller = zoom_class_controller(item.class.name)
    visit "/#{item.basket.urlified_name}" unless on_homepage_already
    item_id = item.to_param #item.private? ? item.id : item.to_param
    contents = [item.description]
    if check_edit_links
      contents << "/#{item.basket.urlified_name}/#{controller}/show/#{item_id}"
      contents << "/#{item.basket.urlified_name}/#{controller}/edit/#{item_id}"
      contents << "/#{item.basket.urlified_name}/#{controller}/history/#{item_id}"
    end
    contents.each do |content|
      check_should_not ? body_should_not_contain(content) : body_should_contain(content)
    end
  end

  def check_recent_topics_include(item)
    visit "/#{item.basket.urlified_name}"
    body_should_contain item.title
    body_should_contain item.description
  end

  def check_private_version_viewable(item, args = {})
    # I tried args[:check_edit_links] || true
    # But it looks like Ruby assigns it true if the args is false (as well as nil)
    # So we have to do a ternary operator to assign it instead
    on_private_homepage_already = !args[:on_private_homepage_already].nil? ? args[:on_private_homepage_already] : false
    check_edit_links = !args[:check_edit_links].nil? ? args[:check_edit_links] : true
    unless on_private_homepage_already
      visit "/#{item.basket.urlified_name}"
      body_should_contain "Private version"
      click_link "Private Version"
    end
    check_homepage_current(item, { :on_homepage_already => true,
                                   :check_edit_links => check_edit_links,
                                   :check_should_not => true })
    item.private_version! if item.has_private_version?
    check_homepage_current(item, { :on_homepage_already => true,
                                   :check_edit_links => check_edit_links })
    body_should_contain "Public version (live)"
    item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
  end

  def check_private_version_not_viewable(item, args = {})
    # I tried args[:check_edit_links] || true
    # But it looks like Ruby assigns it true if the args is false (as well as nil)
    # So we have to do a ternary operator to assign it instead
    on_private_homepage_already = !args[:on_private_homepage_already].nil? ? args[:on_private_homepage_already] : false
    check_edit_links = !args[:check_edit_links].nil? ? args[:check_edit_links] : true
    unless on_private_homepage_already
      visit "/#{item.basket.urlified_name}"
      body_should_not_contain "Private version"
    end
    check_homepage_current(item, { :on_homepage_already => true,
                                   :check_edit_links => check_edit_links })
    item.private_version! if item.has_private_version?
    check_homepage_current(item, { :on_homepage_already => true,
                                   :check_edit_links => check_edit_links,
                                   :check_should_not => true })
    item.public_version! if item.is_private? # make sure we revert it back to public version for the next test
  end

end
