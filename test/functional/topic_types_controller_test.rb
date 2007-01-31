require File.dirname(__FILE__) + '/../test_helper'
require 'topic_types_controller'

# Re-raise errors caught by the controller.
class TopicTypesController; def rescue_action(e) raise e end; end

class TopicTypesControllerTest < Test::Unit::TestCase
  fixtures :topic_types
  fixtures :extended_fields
  fixtures :topic_type_to_field_mappings

  NEW_TOPIC_TYPE = {:name => 'Test TopicType', :description => 'Dummy'} # e.g. {:name => 'Test TopicType', :description => 'Dummy'}
  REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

  def setup
    @controller = TopicTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # Retrieve fixtures via their name
    # @first = topic_types(:first)
    @first = TopicType.find(:first)
    @person_type = topic_types(:person)
    @place_type = topic_types(:place)
    @name_field = extended_fields(:name)
    @capacity_field = extended_fields(:capacity)
  end

  def test_component
    get :component
    assert_response :success
    assert_template 'topic_types/component'
    topic_types = check_attrs(%w(topic_types))
    assert_equal TopicType.find(:all).length, topic_types.length, "Incorrect number of topic_types shown"
  end

  def test_component_update
    get :component_update
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_component_update_xhr
    xhr :get, :component_update
    assert_response :success
    assert_template 'topic_types/component'
    topic_types = check_attrs(%w(topic_types))
    assert_equal TopicType.find(:all).length, topic_types.length, "Incorrect number of topic_types shown"
  end

  def test_create
    topic_type_count = TopicType.find(:all).length
    post :create, {:topic_type => NEW_TOPIC_TYPE}
    topic_type, successful = check_attrs(%w(topic_type successful))
    assert successful, "Should be successful"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    assert_equal topic_type_count + 1, TopicType.find(:all).length, "Expected an additional TopicType"
  end

  def test_create_xhr
    topic_type_count = TopicType.find(:all).length
    xhr :post, :create, {:topic_type => NEW_TOPIC_TYPE}
    topic_type, successful = check_attrs(%w(topic_type successful))
    assert successful, "Should be successful"
    assert_response :success
    assert_template 'create.rjs'
    assert_equal topic_type_count + 1, TopicType.find(:all).length, "Expected an additional TopicType"
  end

  def test_update
    topic_type_count = TopicType.find(:all).length
    post :update, {:id => @first.id, :topic_type => @first.attributes.merge(NEW_TOPIC_TYPE)}
    topic_type, successful = check_attrs(%w(topic_type successful))
    assert successful, "Should be successful"
    topic_type.reload
    NEW_TOPIC_TYPE.each do |attr_name|
      assert_equal NEW_TOPIC_TYPE[attr_name], topic_type.attributes[attr_name], "@topic_type.#{attr_name.to_s} incorrect"
    end
    assert_equal topic_type_count, TopicType.find(:all).length, "Number of TopicTypes should be the same"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_update_xhr
    topic_type_count = TopicType.find(:all).length
    xhr :post, :update, {:id => @first.id, :topic_type => @first.attributes.merge(NEW_TOPIC_TYPE)}
    topic_type, successful = check_attrs(%w(topic_type successful))
    assert successful, "Should be successful"
    topic_type.reload
    NEW_TOPIC_TYPE.each do |attr_name|
      assert_equal NEW_TOPIC_TYPE[attr_name], topic_type.attributes[attr_name], "@topic_type.#{attr_name.to_s} incorrect"
    end
    assert_equal topic_type_count, TopicType.find(:all).length, "Number of TopicTypes should be the same"
    assert_response :success
    assert_template 'update.rjs'
  end

  def test_destroy
    topic_type_count = TopicType.find(:all).length
    post :destroy, {:id => @first.id}
    assert_response :redirect
    assert_equal topic_type_count - 1, TopicType.find(:all).length, "Number of TopicTypes should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_destroy_xhr
    topic_type_count = TopicType.find(:all).length
    xhr :post, :destroy, {:id => @first.id}
    assert_response :success
    assert_equal topic_type_count - 1, TopicType.find(:all).length, "Number of TopicTypes should be one less"
    assert_template 'destroy.rjs'
  end

  def test_add_to_topic_type
    # create a hash in the format we need
    extended_fields_hash = { }
    temp_hash = { }

    @place_type.available_fields.each do |field|
      if field.id.odd?
        temp_hash = { field.id => {:add_checkbox => '0', :required_checkbox => '1'} }
      else
        temp_hash = { field.id => {:add_checkbox => '1', :required_checkbox => '0'} }
      end
      extended_fields_hash.merge!(temp_hash)
    end

    post :add_to_topic_type, :id => @place_type.id, :extended_field => extended_fields_hash

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
protected
  # Could be put in a Helper library and included at top of test class
  def check_attrs(attr_list)
    attrs = []
    attr_list.each do |attr_sym|
      attr = assigns(attr_sym.to_sym)
      assert_not_nil attr,       "Attribute @#{attr_sym} should not be nil"
      assert !attr.new_record?,  "Should have saved the @#{attr_sym} obj" if attr.class == ActiveRecord
      attrs << attr
    end
    attrs.length > 1 ? attrs : attrs[0]
  end
end
