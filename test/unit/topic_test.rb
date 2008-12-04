require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Topic"
    
    # Extend the base class so test files from attachment_fu get put in the 
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test item',
      :topic_type => TopicType.find(:first),
      :basket => Basket.find(:first) }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)
    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
	include FlaggingTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext
  include ItemPrivacyTestHelper::Tests::MovingItemsBetweenBasketsWithDifferentPrivacies
  
  def test_does_not_respond_to_file_private
    topic = Topic.create

    assert !topic.respond_to?(:file_private)
    assert !topic.respond_to?(:file_private=)
  end
  
  # Tests for extended content
  
  def test_xml_attributes
    model = Topic.create!(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content, '<first_names xml_element_name="dc:description">Joe Bloggs</first_names><last_name></last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>')

    assert_valid model

    assert_equal({ "1" => { "first_names" => "Joe Bloggs" }, "2" => { "last_name" => nil }, "3" => { "place_of_birth" => { "xml_element_name" => "dc:subject" } } }, model.xml_attributes)
  end

  def test_xml_attributes_without_data
    model = Topic.create!(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content, '')

    assert_valid model

    assert_equal({}, model.xml_attributes)
  end
  
  
end

