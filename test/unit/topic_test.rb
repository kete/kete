require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Topic"
    
    # Extend the base class so test files from attachment_fu get put in the 
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :title => 'test item',
      :topic_type => TopicType.find(:first),
      :basket => Basket.find(:first)
      # :extended_content => { "first_names" => "Joe", "last_name" => "Bloggs" }
    }

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
  
  def test_does_not_respond_to_file_private
    topic = Topic.create

    assert !topic.respond_to?(:file_private)
    assert !topic.respond_to?(:file_private=)
  end
  
  # Topic specific extended content tests
  
  def test_extended_content_setter
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content = { "first_names" => "Joe", "last_name" => "Bloggs" }
    model.save!
    
    assert_valid model
    
    assert_equal '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>', model.extended_content_xml
  end

  def test_xml_attributes
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content_xml, '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>')
    
    assert_valid model
    
    assert_equal({ "1" => { "first_names" => "Joe" }, "2" => { "last_name" => "Bloggs" }, "3" => { "place_of_birth" => { "xml_element_name" => "dc:subject" } } }, model.xml_attributes)
  end
    
  def test_xml_attributes_without_data
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content_xml, '')
    
    assert !model.valid?
    
    assert_equal({}, model.xml_attributes)
  end
  
  def test_extended_content_pairs_with_multiple_field_values

    field = ExtendedField.create!(
      :label => "Address",
      :xml_element_name => "dc:description",
      :multiple => true,
      :ftype => "text"
    )

    topic_type = TopicType.find_by_name("Person")
    topic_type.form_fields << field
    topic_type.save!
    
    model = Topic.new(@new_model.merge(:topic_type => topic_type))
    model.extended_content = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "Wollaston St.", "2" => "Nelson" } }
    
    assert_nothing_raised do
      model.save!
    end
    
    assert_equal [["first_names", "Joe"], ["last_name", "Bloggs"], ["address_multiple", ["Wollaston St.", "Nelson"]], ["place_of_birth", nil]].sort, \
      model.extended_content_pairs.sort
      
  end
  
  def test_extended_field_required_fields_are_validated

    # Test with valid fields
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content = { "first_names" => "Joe", "last_name" => "Bloggs", "city" => "Wellington" }
    
    assert_valid model
    
    assert_nothing_raised do
      model.save!
    end
    
    # Test with invalid fields
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content = { "first_names" => "", "last_name" => "Bloggs Fam." }
    assert_equal [["first_names", nil], ["last_name", "Bloggs Fam."], ["place_of_birth", nil]].sort, model.extended_content_pairs.sort
    assert !model.valid?
    assert_equal 1, model.errors.size
    
    assert_raises ActiveRecord::RecordInvalid do
      model.save!
    end
  end
  
  def test_extended_field_required_fields_are_validated_with_multiples
    field = ExtendedField.create!(
      :label => "Address",
      :xml_element_name => "dc:description",
      :multiple => true,
      :ftype => "text"
    )

    topic_type = TopicType.find_by_name("Person")
    topic_type.topic_type_to_field_mappings.create(:extended_field => field, :required => true)
    topic_type.save!
    
    model = Topic.new(@new_model.merge(:topic_type => topic_type))
    model.extended_content = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "Wollaston St.", "2" => "" } }
    
    assert_valid model
    
    model.extended_content = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "", "2" => "" } }
    
    assert !model.valid?
    assert_equal 1, model.errors.size
  end
    
end

