require File.dirname(__FILE__) + '/../../test_helper'

class TopicsHelperTest < ActionView::TestCase
  include ApplicationHelper

  context "The topic_types_counts_for" do

    setup do
      @site_basket = Basket.site_basket
      @current_basket = @site_basket
    end

    should "correctly return a display of topic types and counts" do

      topic_types = TopicType.all[0..2]

      parent_topic = Factory(:topic, :title => 'Parent Topic', :topic_type_id => topic_types[0].id, :basket_id => @site_basket.id)
      child_topic_1 = Factory(:topic, :title => 'Child Topic 1', :topic_type_id => topic_types[1].id, :basket_id => @site_basket.id)
      child_topic_2 = Factory(:topic, :title => 'Child Topic 2', :topic_type_id => topic_types[2].id, :basket_id => @site_basket.id)
      ContentItemRelation.new_relation_to_topic(parent_topic, child_topic_1)
      ContentItemRelation.new_relation_to_topic(parent_topic, child_topic_2)

      data = "<ul>" +
               "<li>" +
                 "<a href=\"/en/#{@site_basket.urlified_name}/all/topics/related_to/topic/#{parent_topic.to_param}?topic_type=person\" class=\"small\">" +
                   "#{topic_types[1].name.pluralize} (1)" +
                 "</a>" +
               "</li>" +
               "<li>" +
                 "<a href=\"/en/#{@site_basket.urlified_name}/all/topics/related_to/topic/#{parent_topic.to_param}?topic_type=place\" class=\"small\">" +
                   "#{topic_types[2].name.pluralize} (1)" +
                 "</a>" +
               "</li>" +
             "</ul>"

      assert_equal data, topic_types_counts_for(parent_topic)

    end

  end

end
