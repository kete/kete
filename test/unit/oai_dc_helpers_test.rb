require File.dirname(__FILE__) + '/../test_helper'

::ActionController::UrlWriter.module_eval do
  default_url_options[:host] = 'test.com'
end

class OaiDcHelpersTest < ActiveSupport::TestCase

  include OaiDcHelpers

  context "The oai_dc_xml_dc_relations_and_subjects method" do

    ZOOM_CLASSES.each do |zoom_class|

      should "send back correct xml for #{zoom_class}" do
        parent = Topic.create(:title => 'Parent Topic', :topic_type_id => 1, :basket_id => 1)

        if ATTACHABLE_CLASSES.include?(zoom_class)
          file_data = case zoom_class
          when 'AudioRecording'
            fixture_file_upload('/files/Sin1000Hz.mp3', 'audio/mpeg')
          when 'Document'
            fixture_file_upload('/files/test.pdf', 'application/pdf')
          when 'Video'
            fixture_file_upload('/files/teststrip.mpg', 'video/mpeg')
          end
        end

        options = { :title => 'Child Item', :description => 'Child Description', :basket_id => 1 }
        options[:topic_type_id] = 1 if zoom_class == 'Topic'
        options[:url] = "http://google.co.nz/#{rand}" if zoom_class == 'WebLink'
        options[:uploaded_data] = file_data if (ATTACHABLE_CLASSES - ['StillImage']).include?(zoom_class)
        options.merge!(:commentable_type => 'Topic', :commentable_id => parent.id) if zoom_class == 'Comment'

        item = zoom_class.constantize.create! options

        relate_child_item_to_parent_item(item, parent)

        builder = Nokogiri::XML::Builder.new
        builder.root do |xml|
          item.oai_dc_xml_dc_relations_and_subjects(xml, { })
        end

        expect = "<?xml version=\"1.0\"?>\n<root><dc:subject><![CDATA[Parent Topic]]></dc:subject><dc:relation>http://http://test.com/site/topics/show/#{parent.id}</dc:relation></root>\n"
        assert_equal expect, builder.to_xml
      end

    end

  end

  private

  def relate_child_item_to_parent_item(child_item, parent_item)
    ContentItemRelation.new_relation_to_topic(parent_item, child_item)
  end

end
