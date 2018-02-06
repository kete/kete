# frozen_string_literal: true

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

  context "A topic" do
    setup do
      @topic_type_list_to_first_item = "<ul class=\"breadcrumb\">" +
                                       "<li class=\"first selected-topic-type\">" +
                                       "<a href=\"/en/site/all/topics/of/topic\">Topic</a>" +
                                       "</li>"

      # define method and basket var that some of our dependent helpers expect
      def params
        Hash.new
      end

      @site_basket = Basket.first
    end

    should "return list of single topic type if it is of root level topic type" do
      topic_with_root_topic_type = Factory(:topic)

      single_topic_type_list = @topic_type_list_to_first_item + "</ul>"
      assert_equal single_topic_type_list, topic_type_breadcrumb_for(topic_with_root_topic_type)
    end

    should "return list of hierarchy of topic types if it is of topic type that is a sub topic" do
      topic_type_list_sans_end_tag = @topic_type_list_to_first_item.sub("selected", "ancestor") +
                                     "<li class=\"selected-topic-type\">" +
                                     "<span class=\"breadcrumb-delimiter\"> &raquo; </span>" +
                                     "<a href=\"/en/site/all/topics/of/person\">Person</a></li>"

      parent_id = 2
      assert_equal topic_type_list_sans_end_tag + "</ul>", topic_type_breadcrumb_for(Factory(:topic, :topic_type_id => parent_id))

      # create new topic type below person
      added_topic_type = TopicType.create!(:name => "Subsubtype", :description => "test", :parent_id => parent_id)
      added_topic_type.move_to_child_of TopicType.find(parent_id)

      topic_type_list_sans_end_tag = topic_type_list_sans_end_tag.sub("selected", "ancestor") +
                                     "<li class=\"selected-topic-type\">" +
                                     "<span class=\"breadcrumb-delimiter\"> &raquo; </span>" +
                                     "<a href=\"/en/site/all/topics/of/subsubtype\">Subsubtype</a>" +
                                     "</li>" +
                                     "</ul>"

      assert_equal topic_type_list_sans_end_tag, topic_type_breadcrumb_for(Factory(:topic, :topic_type_id => added_topic_type.id))
    end
  end
end
