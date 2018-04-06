require File.dirname(__FILE__) + '/../test_helper'

class ExtendedFieldTest < ActiveSupport::TestCase
  # fixtures preloaded

  def test_invalid_with_empty_label
    extended_field = ExtendedField.new
    assert !extended_field.valid?
    assert extended_field.errors.invalid?(:label)
  end

  def test_unique_label
    extended_field = ExtendedField.new(
      :label => ExtendedField.find(1).label,
      :description => "yyy"
    )
    assert !extended_field.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], extended_field.errors.on(:label)
  end

  # format of label - can't have special characters
  def test_format_of_label_no_special_characters
    special_chars = ["\'", "\"", "\\", "/", "&", "?", "<", ">", "-"]

    special_chars.each do |sp|
      extended_field = ExtendedField.new(
        :label => sp,
        :description => "yyy"
      )
      assert !extended_field.valid?
      assert extended_field.errors.invalid?(:label)
    end
  end

  # format of label - don't allow labels that are the same as defined columns for topic_type or content_type
  def test_format_of_label_no_reserved_labels
    invalid_label_names = TopicType.column_names + ContentType.column_names

    invalid_label_names.uniq.each do |invalid_label|
      extended_field = ExtendedField.new(
        :label => invalid_label,
        :description => "yyy"
      )
      assert !extended_field.valid?
      assert extended_field.errors.invalid?(:label)
    end
  end

  # format of xml_element_name
  def test_format_of_xml_element_name_no_spaces
    extended_field = ExtendedField.new(
      :label => 'some field',
      :xml_element_name => 'some element name',
      :description => "yyy"
    )
    assert !extended_field.valid?
    assert extended_field.errors.invalid?(:xml_element_name)
  end

  def test_label_does_not_begin_or_end_with_spaces
    extended_field = ExtendedField.create!(
      :label => ' ends and begins with spaces ',
      :description => "yyy"
    )

    assert_equal "ends and begins with spaces", extended_field.label
  end

  def setup
    @person_type = TopicType.find_by_name('Person')
    @place_type = TopicType.find_by_name('Place')
    @city_field = ExtendedField.find_by_label('City')
    @name_field = ExtendedField.find_by_label('Name')
    @user_type = ContentType.find_by_class_name('User')
  end

  ### now for our joins

  # the straight has_many :topic_type_to_field_mappings
  # we'll leave the acts_as_list tests to join model itself

  # add a new field to the form, make sure that position and required are set correctly for defaults
  def test_straight_add_to_form_has_correct_defaults
    form = @name_field.topic_type_to_field_mappings.create(:topic_type_id => @place_type.id)
    assert_equal @place_type.id, form.topic_type_id
    assert_equal @place_type.topic_type_to_field_mappings.size, form.position
    assert !form.required?
  end

  # delete a topic type, makes sure dependent topic_type_to_field_mappings are deleted
  def test_straight_delete_topic_deletes_mappings
    extended_field_id = @name_field.id
    @name_field.destroy
    should_be_empty_list = TopicTypeToFieldMapping.find_all_by_extended_field_id(extended_field_id)
    assert_equal should_be_empty_list.size, 0
  end

  # skipping testing of the association topic_type_forms, since it doesn't have any extensions and it isn't currently in use

  # should never return a field that has already been mapped to a certain topic_type
  def test_find_available_fields_topic_type
    ExtendedField.find_available_fields(@person_type, 'TopicType').each do |field|
      fcount = TopicTypeToFieldMapping.count :conditions => [
        "extended_field_id = :extended_field_id and topic_type_id = :topic_type_id",
        { :extended_field_id => field.id, :topic_type_id => @person_type.id }
      ]
      assert_equal fcount, 0, "find_available_fields list is returning a field that has already been mapped to this topic_type."
    end
  end

  # should never return a field that has already been mapped to a certain content_type
  def test_find_available_fields_content_type
    ExtendedField.find_available_fields(@user_type, 'ContentType').each do |field|
      fcount = TopicTypeToFieldMapping.count :conditions => [
        "extended_field_id = :extended_field_id and topic_type_id = :topic_type_id",
        { :extended_field_id => field.id, :topic_type_id => @user_type.id }
      ]
      assert_equal fcount, 0, "find_available_fields list is returning a field that has already been mapped to this content_type."
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
