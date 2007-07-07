require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeToFieldMappingTest < Test::Unit::TestCase
  # since this is a join model, we need to load test data
  # for the models it joins
  fixtures :topic_types
  fixtures :extended_fields

  fixtures :topic_type_to_field_mappings

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def setup
    @person_type = topic_types(:person)
    @place_type = topic_types(:place)
    @name_field = extended_fields(:extended_fields_006)
    @city_field = extended_fields(:extended_fields_004)
    @capacity_field = extended_fields(:extended_fields_007)
  end

  ## not much in this model yet, but lets test that acts_as_list is working

  # test it shouldn't be possible to have a null position
  def test_null_position
    topic_type_to_field_mapping = TopicTypeToFieldMapping.new(:topic_type_id => @place_type.id,
                                                              :extended_field_id => @capacity_field.id)
    assert topic_type_to_field_mapping.save
    assert topic_type_to_field_mapping.position
  end

  def test_reorder_position
    mapping1 = @person_type.topic_type_to_field_mappings[0]
    mapping2 = @person_type.topic_type_to_field_mappings[1]

    orig_mapping2_id = mapping2.id

    assert mapping1.position.to_i < mapping2.position.to_i

    mapping2.move_to_top

    # i found this a bit confusing, you have to refresh the object
    # after manipulating it's list (sometimes)
    @person_type = TopicType.find_by_name(@person_type[:name])

    mapping1 = @person_type.topic_type_to_field_mappings[0]
    mapping2 = @person_type.topic_type_to_field_mappings[1]

    assert mapping1.position.to_i < mapping2.position.to_i
    assert_equal mapping1.id, orig_mapping2_id
  end

end
