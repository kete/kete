require File.dirname(__FILE__) + '/integration_test_helper'

class HomepageTest < ActionController::IntegrationTest
  context "The homepage" do
    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    context "when recent topics is enabled" do
      setup do
        @@site_basket.update_attributes({ :index_page_number_of_recent_topics => 5,
                                          :index_page_recent_topics_as => 'headlines' })
      end

      teardown do
        @@site_basket.update_attributes({ :index_page_number_of_recent_topics => 0,
                                          :index_page_recent_topics_as => nil })
      end

      context "and topics are added and edited, it" do
        setup do
          1.upto(6) do |i|
            i = i.to_s
            instance_variable_set("@topic#{i}", new_topic(:title => "Topic #{i}"))
          end
          @topic2 = update_item(@topic2, :title => 'Topic Updated 2')
          @topic4 = update_item(@topic4, :title => 'Topic Updated 4')
          visit "/site"
        end

        should "only display the amount of topics requested" do
          body_should_contain "generic-result-header", :number_of_times => 5
        end

        should "order by recently added topics" do
          body_should_not_contain "Topic 1"
          body_should_contain_in_order ['Topic 6', 'Topic 5', 'Topic Updated 4', 'Topic 3', 'Topic Updated 2'],
                                        '<div class="recent-topic-divider"></div>'
        end
      end

      context "and in a new basket" do
        setup do
          @@recent_basket = create_new_basket({ :name => 'Recent Basket' })
          @@recent_basket.update_attributes({ :index_page_number_of_recent_topics => 5,
                                              :index_page_recent_topics_as => 'headlines' })
        end

        context "a new homepage topic is added" do
          setup do
            @topic = new_homepage_topic({ :title => 'Homepage Topic Title',
                                          :description => 'Homepage Topic Description' }, @@recent_basket)
          end

          should "not show homepage topic in recent basket recent results" do
            visit '/recent_basket'
            body_should_not_contain '>Homepage Topic Title<'
          end

          should "show the recent topic when appropriate" do
            verify_site_basket_recent_topics('>Homepage Topic Title<', @@recent_basket)
          end
        end

        context "a new topic is added" do
          setup do
            @topic = new_topic({ :title => 'Topic Title',
                                 :description => 'Topic Description' }, @@recent_basket)
          end

          should "show topic in recent basket recent results" do
            visit '/recent_basket'
            body_should_contain '>Topic Title<'
          end

          should "show the recent topic when appropriate" do
            verify_site_basket_recent_topics('>Topic Title<', @@recent_basket)
          end
        end
      end
    end

    context "when archive by types is enabled" do
      setup do
        @@homepage_basket = create_new_basket({ :name => 'Homepage Basket' })
        @@homepage_basket.update_attributes({ :show_privacy_controls => true, :index_page_archives_as => 'by type' })
        add_admin_as_member_to(@@homepage_basket)
      end

      teardown do
        @@homepage_basket.update_attributes({ :show_privacy_controls => false, :index_page_archives_as => nil })
      end

      context "and a public topic has been added, archive by type" do
        setup do
          @topic = new_topic({ :title => 'Public Item' }, @@homepage_basket)
        end

        teardown do
          @topic = delete_item(@topic)
        end

        should "only show public items links" do
          visit "/homepage_basket"
          body_should_not_contain Regexp.new("\\( <a (.+)>(\\d+)</a> \\| private: <a (.+)>(\\d+)</a> \\)"),
                                  :message => "Public and private links together should not be visible on the site basket, but they are."
          body_should_contain Regexp.new("\\( <a (.+)>(\\d+)</a> \\)"),
                              :message => "The public link should be visible on the site basket, but isn't."
        end
      end

      context "and a private topic has been added, archive by type" do
        setup do
          @topic = new_topic({ :title => 'Private Item', :private_true => true }, @@homepage_basket)
        end

        teardown do
          @topic = delete_item(@topic)
        end

        should "show the private items links" do
          visit "/homepage_basket"
          body_should_contain Regexp.new("private: <a (.+)>(\\d+)</a> \\)"),
                              :message => "The private link should be visible on the site basket, but isn't."
        end

        context "and the user is logged out, archive by type" do
          setup do
            logout
          end

          teardown do
            login_as('admin')
          end

          should "not show the private items links" do
            visit "/homepage_basket"
            body_should_not_contain Regexp.new("private: <a (.+)>(\\d+)</a> \\)"),
                                    :message => "The private link should not be visible on the site basket, but is."
          end
        end
      end

      context "and both public and private topics are added, archive by type" do
        setup do
          @topic1 = new_topic({ :title => 'Public Item' }, @@homepage_basket)
          @topic2 = new_topic({ :title => 'Private Item', :private_true => true }, @@homepage_basket)
        end

        teardown do
          @topic1 = delete_item(@topic1)
          @topic2 = delete_item(@topic2)
        end

        should "show both public and private item links" do
          visit "/homepage_basket"
          body_should_contain Regexp.new("\\( <a (.+)>(\\d+)</a> \\| private: <a (.+)>(\\d+)</a> \\)"),
                              :message => "Both public and private links should be visible on the site basket, but arn't."
        end

        context "and the user is logged out, archive by type" do
          setup do
            logout
          end

          teardown do
            login_as('admin')
          end

          should "show the public items links" do
            visit "/homepage_basket"
            body_should_contain Regexp.new("\\( <a (.+)>(\\d+)</a> \\)"),
                                :message => "The public link should be visible on the site basket, but isn't."
          end

          should "not show the private items links" do
            visit "/homepage_basket"
            body_should_not_contain Regexp.new("private: <a (.+)>(\\d+)</a> \\)"),
                                    :message => "The private link should not be visible on the site basket, but is."
          end
        end
      end
    end

    context "when changing homepage topic" do
      context "by linking to an existing topic" do
        should "successfully replace homepage" do
          bootstrap_zebra_with_initial_records(true)
          visit "/#{@@about_basket.urlified_name}/baskets/homepage_options/#{@@about_basket.id}"
          click_link "Link to new basket homepage topic"
          fill_in 'search_terms', :with => 'a'
          click_button 'Search for Topics'
          body_should_not_contain 'No Topics found'
          body_should_contain '(current homepage topic)'
          topic_id = Topic.find_by_title('House Rules').id
          chooses "homepage_topic_id_#{topic_id}"
          click_button 'Change Homepage Topic'
          body_should_contain 'Homepage topic changed successfully'
          visit "/#{@@about_basket.urlified_name}/baskets/homepage_options/#{@@about_basket.id}"
          body_should_contain Regexp.new("House Rules")
        end
      end
    end

    context "when no homepage topic exists" do
      setup do
        @@homepage_basket = create_new_basket({ :name => 'No Homepage Topic' })
      end

      should "be able to create a homepage topic from the blank basket index" do
        visit "/#{@@homepage_basket.urlified_name}"
        click_link 'Create basket homepage'
        click_button 'Choose Type'
        fill_in 'topic_title', :with => 'Test Homepage'
        click_button 'Create'
        body_should_contain 'Basket homepage was successfully created.'
        body_should_not_contain 'Create homepage topic'
        assert request.url =~ /\/#{@@homepage_basket.urlified_name}/
      end
    end

    context "when a homepage topic exists" do
      setup do
        @@homepage_topic = new_topic :title => 'Custom Homepage Topic'
        @@site_basket.update_index_topic(@@homepage_topic)

        add_jack_as_admin_to(@@site_basket)
        add_jill_as_regular_user
      end

      should "display edit and history links to only those who have access" do
        visit "/#{@@site_basket.urlified_name}"
        body_should_contain Regexp.new("<a .*/site/topics/edit/#{@@homepage_topic.id}.*>Edit</a>")
        body_should_contain Regexp.new("<a .*/site/topics/history/#{@@homepage_topic.id}.*>History</a>")

        login_as(:jack)
        visit "/#{@@site_basket.urlified_name}"
        body_should_contain Regexp.new("<a .*/site/topics/edit/#{@@homepage_topic.id}.*>Edit</a>")
        body_should_contain Regexp.new("<a .*/site/topics/history/#{@@homepage_topic.id}.*>History</a>")

        login_as(:jill)
        visit "/#{@@site_basket.urlified_name}"
        body_should_not_contain Regexp.new("<a .*/site/topics/edit/#{@@homepage_topic.id}.*>Edit</a>")
        body_should_not_contain Regexp.new("<a .*/site/topics/history/#{@@homepage_topic.id}.*>History</a>")
      end
    end
  end

  private

  def verify_site_basket_recent_topics(text, basket)
    basket.settings[:disable_site_recent_topics_display] = false
    visit '/site'
    body_should_contain text
    basket.settings[:disable_site_recent_topics_display] = true
    visit '/site'
    body_should_not_contain text
  end
end
