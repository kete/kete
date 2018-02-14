require File.dirname(__FILE__) + '/../test_helper'

class OaiDcHelpersTest < ActiveSupport::TestCase
  include OaiDcHelpers

  ZOOM_CLASSES.each do |zoom_class|
    context "In #{zoom_class}, the oai_dc_xml_dc_relations_and_subjects method" do
      setup do
        @parent = Topic.create(:title => 'Parent Topic', :topic_type_id => 1, :basket_id => 1)

        options = { 
          :title => 'Child Item',
          :description => 'Child Description' 
        }

        if zoom_class == 'Comment'
          options = { 
            :commentable_type => 'Topic',
            :commentable_id => @parent.id 
          }.merge(options)
        end

        item_for(zoom_class, options)

        relate_child_item_to_parent_item(@item, @parent)
      end

      should "send back correct xml for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_relations_and_subjects(xml, { :host => "www.example.com" })
        end

        expect = "<dc:subject><![CDATA[Parent Topic]]></dc:subject><dc:relation>http://www.example.com/site/topics/show/#{@parent.id}</dc:relation>"
        assert_equal expect, builder.to_stripped_xml
      end
    end

    context "In #{zoom_class}, the oai_dc_xml_dc_creators_and_date method" do
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

    context "In #{zoom_class}, the oai_dc_xml_dc_title method" do
      setup do
        item_for(zoom_class)
      end

      should "have xml for dc:title for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_title(xml)
        end

        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_title_xml(binding))
      end

      should "have xml for xml:lang as attribute on dc:title element for #{zoom_class}, if xml:lang is passed in" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_title(xml, "xml:lang" => I18n.default_locale)
        end

        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_title_with_lang_xml(binding))
      end
    end

    context "In #{zoom_class}, the oai_dc_xml_dc_description method" do
      setup do
        item_for(zoom_class)
      end

      should "have xml for dc:description for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_description(xml, @item.description)
        end
        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_description_xml(binding))
      end

      should "output correct dc:description for #{zoom_class} when given only xml argument" do
        has_short_summary = false
        if %w[Topic Document].include?(zoom_class)
          @item.short_summary = "Short Summary"
          @item.save
          @item.reload
          has_short_summary = true
        end

        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_description(xml)
        end

        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_description_xml_when_only_xml(binding))
        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_short_summary_xml_when_only_xml(binding)) if has_short_summary
      end

      should "have xml for xml:lang as attribute on dc:description element for #{zoom_class}, if xml:lang is passed in" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_description(xml, @item.description, "xml:lang" => I18n.default_locale)
        end

        assert builder.to_stripped_xml.include?("<dc:description xml:lang=\"#{I18n.default_locale}\"><![CDATA[Description]]></dc:description>")
      end
    end

    context "In #{zoom_class}, the oai_dc_xml_tags_to_dc_subjects method" do
      setup do
        item_for(zoom_class)

        @item.tag_list << "tag"
        @item.save
        @item.reload
        @item.add_as_contributor(User.first, @item.version)
      end

      should "have xml for dc:subject for an item's tags for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_tags_to_dc_subjects(xml)
        end
        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_tags_xml(binding))
      end
    end

    context "In #{zoom_class}, the oai_dc_xml_dc_extended_content method" do
      setup do
        item_for(zoom_class)

        # add an extended field to the top most topic_type (if topic)
        # or this content_type
        create_extended_field(
          :label => 'An extended field',
          :ftype => 'text',
          :xml_element_name => 'dc:description'
        )

        @type = zoom_class == 'Topic' ? TopicType.first : ContentType.find_by_class_name(zoom_class)

        if zoom_class == 'Topic'
          @extended_field.topic_type_to_field_mappings.create(:topic_type_id => @type.id)
        else
          @extended_field.content_type_to_field_mappings.create(:content_type_id => @type.id)
        end

        # add a value for this extended field
        @item.an_extended_field = "some text"
        @item.save
        @item.reload
        @item.add_as_contributor(User.first, @item.version)
      end

      should "have xml for dc:description for an item's extended field mapped to dc:description for #{zoom_class}" do
        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          @item.oai_dc_xml_dc_extended_content(xml)
        end
        assert builder.to_stripped_xml.include?(HasValue.oai_dc_helpers_extended_content_xml(binding))
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
