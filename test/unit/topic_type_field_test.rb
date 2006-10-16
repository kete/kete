require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeFieldTest < Test::Unit::TestCase
  fixtures :topic_type_fields

  # The TopicTypeField model contains many things that
  # need to be tested using the join model TopicTypeToFieldMapping
  # and TopicType, so we load their fixtures here
  fixtures :topic_types
  fixtures :topic_type_to_field_mappings

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_invalid_with_empty_name
    topic_type_field = TopicTypeField.new
    assert !topic_type_field.valid?
    assert topic_type_field.errors.invalid?(:name)
  end

  def test_unique_name
    topic_type_field = TopicTypeField.new(:name       => topic_type_fields(:first_names).name,
                          :description => "yyy")
    assert !topic_type_field.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], topic_type_field.errors.on(:name)
  end

  def setup
    @person_type = topic_types(:person)
    @place_type = topic_types(:place)
    @name_field = topic_type_fields(:name)
    @capacity_field = topic_type_fields(:capacity)
  end

  ### now for our joins

  # the straight has_many :topic_type_to_field_mappings
  # we'll leave the acts_as_list tests to join model itself

  # add a new field to the form, make sure that position and required are set correctly for defaults
  def test_straight_add_to_form_has_correct_defaults
    form = @name_field.topic_type_to_field_mappings.create(:topic_type_id => @place_type.id)
    assert_equal @place_type.id, form.topic_type_id
    assert_equal @place_type.topic_type_to_field_mappings.size, form.position
    assert_equal false, form.required?
  end

  # delete a topic type, makes sure dependent topic_type_to_field_mappings are deleted
  def test_straight_delete_topic_deletes_mappings
    topic_type_field_id = @name_field.id
    @name_field.destroy
    should_be_empty_list = TopicTypeToFieldMapping.find_all_by_topic_type_field_id(topic_type_field_id)
    assert_equal should_be_empty_list.size, 0
  end

  # skipping testing of the association topic_type_forms, since it doesn't have any extensions and it isn't currently in use

  # should never return a field that has already been mapped to a certain topic_type
  def test_find_available_fields
    TopicTypeField.find_available_fields(@person_type).each do |field|
      fcount = TopicTypeToFieldMapping.count :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                              {:topic_type_field_id => field.id, :topic_type_id => @person_type.id }]
      assert fcount == 0 , "find_available_fields list is returning a field that has already been mapped to this topic_type."
    end
  end

  # these two should always return 0
  def test_add_checkbox
    test_value = @name_field.add_checkbox
    assert_equal test_value, 0, "add_checkbox should always return 0 as it's starting value"
  end

  def test_required_checkbox
    test_value = @name_field.required_checkbox
    assert_equal test_value, 0, "required_checkbox should always return 0 as it's starting value"
  end

end
