require File.dirname(__FILE__) + '/../test_helper'

class LicensesControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  fixtures :licenses

  def setup
    @base_class = "License"
    @assignment_var = "record" # singular, lowercase
    load_test_environment
    login_as(:admin)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model =     { :name => 'License1',
                       :description => 'License1',
                       :url => 'http://www.licenses.com/license1.html',
                       :is_available => true,
                       :is_creative_commons => true }
    @updated_model = { :name => 'License2',
                       :description => 'License2',
                       :url => 'http://www.licenses.com/license2.html',
                       :is_available => true,
                       :is_creative_commons => true }
  end

  def test_index
    get :index, index_path
    assert_viewing_template 'list'
    assert_var_assigned true
    assert_equal 4, assigns(:records).size
  end

  def test_show
    get :show, show_path({ :id => licenses(:one).id })
    assert_viewing_template 'show'
    assert_var_assigned
  end

  # Kieran Pilkington, 2008/08/11
  # This will fail because we currently have no validations in place to make sure something is entered
  #def test_shouldnt_create_license
  #  assert_no_difference('License.count') do
  #    post :create, {:urlified_name => 'site', :record => {}}
  #  end
  #end

  def test_new
    get :new, new_path
    assert_viewing_template 'create'
    assert_var_assigned
  end

  def test_create
    create_record
    assert_var_assigned
    assert_attributes_same_as @new_model
    assert_redirect_to( index_path )
  end

  def test_edit
    get :edit, edit_path({ :id => licenses(:one).id })
    assert_viewing_template 'update'
    assert_var_assigned
  end

  def test_update
    update_record( {}, { :id => licenses(:one).id } )
    assert_var_assigned
    assert_attributes_same_as @updated_model
    assert_redirect_to( index_path.merge(:action => 'index', :id => licenses(:one).id) )
  end

  def test_destroy
    destroy_record({ :id => licenses(:one).id })
    assert_redirect_to( index_path.merge(:action => 'index', :id => licenses(:one).id) )
  end
end
