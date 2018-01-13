require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeToFieldMappingTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @person_type = TopicType.find_by_name('Person')
    @place_type = TopicType.find_by_name('Place')
    @city_field = ExtendedField.find_by_label('City')
  end

  # ## not much in this model yet, but lets test that acts_as_list is working

  # test it shouldn't be possible to have a null position
  def test_null_position
    topic_type_to_field_mapping = TopicTypeToFieldMapping.new(:topic_type_id => @place_type.id,
      :extended_field_id => @city_field.id)
    assert topic_type_to_field_mapping.save
    assert topic_type_to_field_mapping.position
  end

  def test_reorder_position
    mapping1 = @person_type.topic_type_to_field_mappings[0]
    mapping2 = @person_type.topic_type_to_field_mappings[1]

    orig_mapping2_id = mapping2.id

    assert mapping1.position.to_i < mapping2.position.to_i

    mapping2.move_to_top

    # i found this a bit confusing, you have to refresh the object after
    # manipulating it's list (sometimes)
    @person_type = TopicType.find_by_name('Person')

    mapping1 = @person_type.topic_type_to_field_mappings[0]
    mapping2 = @person_type.topic_type_to_field_mappings[1]

    assert mapping1.position.to_i < mapping2.position.to_i
    assert_equal mapping1.id, orig_mapping2_id
  end

  context "When the Person topic type has two extended field mappings (one single value, one multiple)" do
    setup do
      @topic_type, @mappings = setup_mappings_of_class('TopicType', 'Person')
    end

    context "and each mapping isn't being used or it's blank, it" do
      setup do
        @mappings.each do |mapping|
          populate_empty_extended_field_data_for('Topic', mapping, :topic_type_id => @topic_type.id)
        end
      end

      should "be able to be destroyed" do
        @mappings.each do |mapping|
          assert !mapping.used_by_items?
        end
      end
    end

    context "and each mapping is being used, it" do
      setup do
        @mappings.each do |mapping|
          populate_filled_in_extended_field_data_for('Topic', mapping, :topic_type_id => @topic_type.id)
        end
      end

      should "not be able to be destroyed" do
        @mappings.each do |mapping|
          assert mapping.used_by_items?
        end
      end
    end
  end

  context "When dealing with required and private_only fields, you" do
    setup do
      @topic_type, @mappings = setup_mappings_of_class('TopicType', 'Person')
    end

    should "not be allowed to have both required and private_only to be enabled" do
      mapping = @mappings.last
      mapping.required = true
      mapping.private_only = true
      assert !mapping.valid?
      assert_equal 'Mapping cannot be required and private only.', mapping.errors['base']
    end
  end
end
