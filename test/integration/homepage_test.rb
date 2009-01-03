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

      context "and a new homepage topic is added, it" do

        setup do
        end

        should "not show homepage topic in any baskets recent results" do
        end

      end

      context "and the recent topics includes a default topic" do

        context "and when in the site basket, the topic" do

          should "not be displayed" do
          end

        end

        context "and when not in the site basket, the topic" do

          should "be displayed" do
          end

        end

      end

    end

  end

end
