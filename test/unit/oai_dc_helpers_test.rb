require File.dirname(__FILE__) + '/../test_helper'

class OaiDcHelpersTest < ActiveSupport::TestCase
  include OaiDcHelpers

  context "The oai_dc_xml_dc_relations_and_subjects method" do

    ZOOM_CLASSES.each do |zoom_class|

      should "send back correct xml for #{zoom_class}" do
        parent = Topic.create(:title => 'Parent Topic', :topic_type_id => 1, :basket_id => 1)

        options = { :title => 'Child Item',
          :description => 'Child Description'}

        if zoom_class == 'Comment'
          options = { :commentable_type => 'Topic',
            :commentable_id => parent.id }.merge(options)
        end

        item_for(zoom_class, options)


        relate_child_item_to_parent_item(@item, parent)

        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_relations_and_subjects(xml, { :host => "www.example.com" })
        end

        expect = "<dc:subject><![CDATA[Parent Topic]]></dc:subject><dc:relation>http://www.example.com/site/topics/show/#{parent.id}</dc:relation>"
        assert_equal expect, builder.to_stripped_xml
      end
    end
  end

  context "The oai_dc_xml_dc_creators_and_date method" do

    ZOOM_CLASSES.each do |zoom_class|
      setup do
        item_for(zoom_class)
      end

      should "have xml for dc:date for #{zoom_class} when ADD_DATE_CREATED_TO_ITEM_SEARCH_RECORD is true" do
        set_constant :ADD_DATE_CREATED_TO_ITEM_SEARCH_RECORD, true
        assert oai_dc_xml_dc_creators_and_date_as_string.include?("dc:date")
      end

      should "not have xml for dc:date for #{zoom_class} when ADD_DATE_CREATED_TO_ITEM_SEARCH_RECORD is false" do
        set_constant :ADD_DATE_CREATED_TO_ITEM_SEARCH_RECORD, false
        assert !oai_dc_xml_dc_creators_and_date_as_string.include?("dc:date")
      end
    end
  end

  context "The oai_dc_xml_dc_title method" do

    ZOOM_CLASSES.each do |zoom_class|
      setup do
        item_for(zoom_class)
      end

      should "have xml for dc:title for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_title(xml).include?("dc:title")
        end
      end
    end
  end

  private

  def relate_child_item_to_parent_item(child_item, parent_item)
    ContentItemRelation.new_relation_to_topic(parent_item, child_item)
  end

  def oai_dc_xml_dc_creators_and_date_as_string
    builder = Nokogiri::XML::Builder.new
    builder.root do |xml|
      @item.oai_dc_xml_dc_creators_and_date(xml)
    end
    builder.to_stripped_xml
  end

end
