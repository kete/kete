require File.dirname(__FILE__) + '/../test_helper'
require 'topic_types_controller'

# Re-raise errors caught by the controller.
class TopicTypesController; def rescue_action(e) raise e end; end

class TopicTypesControllerTest < Test::Unit::TestCase
  # fixtures are preloaded

  include AuthenticatedTestHelper

  # e.g. {:name => 'Test TopicType', :description => 'Dummy'}
  NEW_TOPIC_TYPE = {:name => 'Test TopicType',
    :description => 'Dummy'}

  # put hash or string redirection that you normally expect
  REDIRECT_TO_MAIN = {:action => 'list'}
  REDIRECT_TO_EDIT = {:action => 'edit'}

  def setup
    @controller = TopicTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # Retrieve fixtures via their name
    @first = TopicType.find(:first)
    @person_type = TopicType.find_by_name('Person')
    @place_type = TopicType.find_by_name('Place')
    @name_field = ExtendedField.find_by_label('Name')
    @site_basket = Basket.find(:first)

    # login for the time being, may change this on a test by test basis
    login_as :admin
  end

  def test_create
    topic_type_count = TopicType.find(:all).length
    post :create, {:topic_type => NEW_TOPIC_TYPE, :urlified_name => @site_basket.urlified_name}
    topic_type = check_attrs(%w(topic_type))
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_EDIT
    assert_equal topic_type_count + 1, TopicType.find(:all).length, "Expected an additional TopicType"
  end

  def test_update
    topic_type_count = TopicType.find(:all).length
    post :update, {:id => @first.id, :topic_type => @first.attributes.merge(NEW_TOPIC_TYPE), :urlified_name => @site_basket.urlified_name}
    topic_type = check_attrs(%w(topic_type))
    topic_type.reload
    NEW_TOPIC_TYPE.each do |attr_name|
      assert_equal NEW_TOPIC_TYPE[attr_name], topic_type.attributes[attr_name], "@topic_type.#{attr_name.to_s} incorrect"
    end
    assert_equal topic_type_count, TopicType.find(:all).length, "Number of TopicTypes should be the same"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_EDIT
  end

  def test_destroy
    topic_type_count = TopicType.find(:all).length
    post :destroy, {:id => @person_type.id, :urlified_name => @site_basket.urlified_name}
    assert_response :redirect
    assert_equal topic_type_count - 1, TopicType.find(:all).length, "Number of TopicTypes should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
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

    post :add_to_topic_type, :id => @place_type.id, :extended_field => extended_fields_hash, :urlified_name => @site_basket.urlified_name

    # a simple test to make sure this worked... there should no longer be any available fields
    assert_equal @place_type.available_fields.size, 0
    # this will need to change to edit, possibly
    assert_redirected_to :action => 'edit', :id => @place_type
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

    post :reorder_fields_for_topic_type, :id => @person_type.id, :mapping => mappings_hash, :urlified_name => @site_basket.urlified_name

    # i found this a bit confusing, you have to refresh the object
    # after manipulating it's list (sometimes)
    @person_type = TopicType.find_by_name(@person_type[:name])

    assert_equal @person_type.topic_type_to_field_mappings.first.id, org_last_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    assert_equal @person_type.topic_type_to_field_mappings.last.id, org_first_mapping_id, "The reorder_fields_for_topic_type action didn't swap first and last positions as expected."
    # this will need to change to edit, possibly
    assert_redirected_to :action => 'edit', :id => @person_type
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
