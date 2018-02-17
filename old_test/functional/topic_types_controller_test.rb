require File.dirname(__FILE__) + '/../test_helper'

class TopicTypesControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "TopicType"
    load_test_environment
    login_as(:admin)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :parent_id => 1,
      :name => 'TopicType1',
      :description => 'TopicType1'
    }
    @updated_model = {
      :name => 'TopicType2',
      :description => 'TopicType2'
    }
  end

  def test_index_and_list
    get :index, index_path
    assert_redirect_to :action => 'list'

    get :list, index_path({ :action => 'list' })
    assert_viewing_template 'topic_types/list'
    assert_var_assigned true
    assert_equal 5, assigns(:topic_types).size
  end

  def test_new
    get :new, new_path({ :parent_id => 1 })
    assert_viewing_template 'topic_types/new'
    assert_var_assigned
  end

  def test_create
    create_record
    assert_var_assigned
    assert_attributes_same_as @new_model
    assert_redirect_to(edit_path({ :id => assigns(:topic_type).id }))
    assert_equal 'Topic type was successfully created.', flash[:notice]
  end

  def test_edit
    get :edit, edit_path
    assert_viewing_template 'topic_types/edit'
    assert_var_assigned
  end

  def test_update
    update_record
    assert_var_assigned
    assert_attributes_same_as @updated_model
    assert_redirect_to(edit_path({ :id => assigns(:topic_type).id }))
    assert_equal 'Topic type was successfully updated.', flash[:notice]
  end

  def test_destroy
    destroy_record({ :id => 4 })
    assert_redirect_to(index_path({ :action => 'list' }))
    assert_equal 'Topic type was successfully deleted.', flash[:notice]
  end

  def test_add_to_topic_type
    @place_type = TopicType.find_by_name('Place')
    # create a hash in the format we need
    extended_fields_hash = {}
    temp_hash = {}

    @place_type.available_fields.each do |field|
      temp_hash = if field.id.odd?
        { field.id => { :add_checkbox => '0', :required_checkbox => '1' } }
      else
        { field.id => { :add_checkbox => '1', :required_checkbox => '0' } }
                  end
      extended_fields_hash.merge!(temp_hash)
    end

    post :add_to_item_type, :id => @place_type.id, :extended_field => extended_fields_hash, :urlified_name => 'site'

    # a simple test to make sure this worked... there should no longer be any available fields
    assert_equal @place_type.available_fields.size, 0
    assert_redirect_to(edit_path({ :id => @place_type.id }))
  end

  # this test reordering without using acts_as_tree functionality
  # send topic_type id, subhashes for each topic_type_to_field_mapping.id with new position
  def test_reorder_fields_for_topic_type
    @person_type = TopicType.find_by_name('Person')
    # record the original id of the first and last mapping
    num_fields = @person_type.topic_type_to_field_mappings.size
    org_first_mapping_id = @person_type.topic_type_to_field_mappings.first.id
    org_last_mapping_id = @person_type.topic_type_to_field_mappings.last.id

    # create a hash in the format we need with first and last mappings positions' swapped
    mappings_hash = {}
    temp_hash = {}

    @person_type.topic_type_to_field_mappings.each do |mapping|
      temp_hash = if mapping.id == org_first_mapping_id
        { mapping.id => { :position => num_fields } }
      elsif mapping.id == org_last_mapping_id
        { mapping.id => { :position => '1' } }
      else
        { mapping.id => { :position => mapping.position } }
                  end
      mappings_hash.merge!(temp_hash)
    end

    post :reorder_fields, :id => @person_type.id, :mapping => mappings_hash, :urlified_name => 'site'

    # i found this a bit confusing, you have to refresh the object
    # after manipulating it's list (sometimes)
    @person_type = TopicType.find_by_name(@person_type[:name])

    assert_equal @person_type.topic_type_to_field_mappings.first.id, org_last_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    assert_equal @person_type.topic_type_to_field_mappings.last.id, org_first_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    # this will need to change to edit, possibly
    assert_redirect_to(edit_path({ :id => @person_type.id }))
  end
end
