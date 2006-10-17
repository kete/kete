require File.dirname(__FILE__) + '/../test_helper'
require 'topic_types_controller'

# Re-raise errors caught by the controller.
class TopicTypesController; def rescue_action(e) raise e end; end

class TopicTypesControllerTest < Test::Unit::TestCase

  fixtures :topic_types
  fixtures :topic_type_fields
  fixtures :topic_type_to_field_mappings

  def setup
    @controller = TopicTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @person_type = topic_types(:person)
    @place_type = topic_types(:place)
    @name_field = topic_type_fields(:name)
    @capacity_field = topic_type_fields(:capacity)
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  # send topic_type id, subhashes for each topic_type_field.id with add_checkbox and required_checkbox values
  def test_add_to_topic_type
    # create a hash in the format we need
    topic_type_fields_hash = { }
    temp_hash = { }

    @place_type.available_fields.each do |field|
      if field.id.odd?
        temp_hash = { field.id => {:add_checkbox => '0', :required_checkbox => '1'} }
      else
        temp_hash = { field.id => {:add_checkbox => '1', :required_checkbox => '0'} }
      end
      topic_type_fields_hash.merge!(temp_hash)
    end

    post :add_to_topic_type, :id => @place_type.id, :topic_type_field => topic_type_fields_hash

    # a simple test to make sure this worked... there should no longer be any available fields
    assert_equal @place_type.available_fields.size, 0
    # this will need to change to edit, possibly
    assert_redirected_to :controller => 'topic_types' , :action => 'index'
  end

  # this test reordering without using acts_as_tree functionality
  # send topic_type id, subhashes for each topic_type_to_field_mapping.id with new position
  def test_reorder_fields_for_topic_type
    # record the original id of the first and last mapping
    num_fields = @person_type.topic_type_to_field_mappings.size
    org_first_mapping_id = @person_type.topic_type_to_field_mappings.first.id
    org_last_mapping_id = @person_type.topic_type_to_field_mappings.last.id

    # create a hash in the format we need with first and last mappings positions' swapped
    mappings_hash = { }
    temp_hash = { }

    @person_type.topic_type_to_field_mappings.each do |mapping|
      if mapping.id == org_first_mapping_id
        temp_hash = { mapping.id => {:position => num_fields} }
      elsif mapping.id == org_last_mapping_id
        temp_hash = { mapping.id => {:position => '1'} }
      else
        temp_hash = { mapping.id => {:position => mapping.position} }
      end
      mappings_hash.merge!(temp_hash)
    end

    post :reorder_fields_for_topic_type, :id => @person_type.id, :mapping => mappings_hash

    # i found this a bit confusing, you have to refresh the object
    # after manipulating it's list (sometimes)
    @person_type = TopicType.find_by_name(@person_type[:name])

    assert_equal @person_type.topic_type_to_field_mappings.first.id, org_last_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    assert_equal @person_type.topic_type_to_field_mappings.last.id, org_first_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    # this will need to change to edit, possibly
    assert_redirected_to :controller => 'topic_types', :action => 'index'
  end
end
