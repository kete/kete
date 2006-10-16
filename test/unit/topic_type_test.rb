require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeTest < Test::Unit::TestCase
  fixtures :topic_types

  # The TopicType model contains many things that are better
  # need to be tested using the join model TopicTypeToFieldMapping
  # and TopicTypeFields, so we load their fixtures here
  fixtures :topic_type_fields
  fixtures :topic_type_to_field_mappings

  # cover the basics first
  def test_truth
    assert true
  end

  def test_invalid_with_empty_attributes
    topic_type = TopicType.new
    assert !topic_type.valid?
    assert topic_type.errors.invalid?(:name)
    assert topic_type.errors.invalid?(:description)
  end

  def test_unique_name
    topic_type = TopicType.new(:name       => topic_types(:person).name,
                               :description => "yyy")
    assert !topic_type.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], topic_type.errors.on(:name)
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
  def test_straight_add_field_has_correct_defaults
    field = @person_type.topic_type_to_field_mappings.create(:topic_type_field_id => topic_type_fields(:city).id)
    assert_equal topic_type_fields(:city).id, field.topic_type_field_id
    assert_equal @person_type.topic_type_to_field_mappings.size, field.position
    assert_equal false, field.required?
  end

  # delete a topic type, makes sure dependent topic_type_to_field_mappings are deleted
  def test_straight_delete_topic_deletes_mappings
    topic_type_id = @person_type.id
    @person_type.destroy
    should_be_empty_list = TopicTypeToFieldMapping.find_all_by_topic_type_id(topic_type_id)
    assert_equal should_be_empty_list.size, 0
  end

  ## the has_many :through association extensions

  # form_fields
  # add a new field to the form using the extension, make sure that position and required are set correctly for defaults
  def test_form_fields_add_field_has_correct_defaults
    @place_type.form_fields << @name_field

    mapping =
      TopicTypeToFieldMapping.find(:first,
                                   :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                   {:topic_type_field_id => @name_field.id, :topic_type_id => @place_type.id }] )
    assert_equal @place_type.form_fields.size, mapping.position
    assert_equal false, mapping.required?
  end

  # topic_type.form_fields should be ordered by position
  def test_form_fields_ordered_by_position
    @place_type.form_fields << @name_field
    @place_type.form_fields << @capacity_field

    last_position = 0

    @place_type.form_fields.each do |field|
      mapping =
        TopicTypeToFieldMapping.find(:first,
                                     :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                     {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }] )
      test_position = mapping.position.to_i
      last_position = test_position
      assert test_position <= last_position, "form_fields not listed in order of position"
    end
  end

  # required_form_fields
  # add a new field to the form using the extension, make sure that position and required are set correctly for defaults
  def test_required_form_fields_add_field_has_correct_defaults
    @place_type.required_form_fields << @capacity_field

    mapping =
      TopicTypeToFieldMapping.find(:first,
                                   :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                   {:topic_type_field_id => @capacity_field.id, :topic_type_id => @place_type.id }] )
    assert_equal @place_type.form_fields.size, mapping.position
    assert_equal true, mapping.required?
  end


  # topic_type.required_form_fields should be ordered by position
  def test_required_form_fields_ordered_by_position
    @place_type.required_form_fields << @name_field
    @place_type.required_form_fields << @capacity_field

    last_position = 0

    @place_type.required_form_fields.each do |field|
      mapping =
        TopicTypeToFieldMapping.find(:first,
                                     :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                     {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }] )
      test_position = mapping.position.to_i
      last_position = test_position
      assert test_position <= last_position, "required_form_fields not listed in order of position"
    end
  end

  # we shouldn't see any fields that have been mapped to this topic_type already
  def test_available_fields_not_already_mapped
    @place_type.available_fields.each do |field|
      fcount = TopicTypeToFieldMapping.count :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                              {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }]
      assert fcount == 0 , "There is a field listed in available_fields that has already been mapped to this topic_type."
    end
  end
end
