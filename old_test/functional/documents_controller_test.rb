require File.dirname(__FILE__) + '/../test_helper'

class DocumentsControllerTest < ActionController::TestCase
  # Load fixtures for users for login..
  fixtures :users

  include KeteTestFunctionalHelper
  include ItemPrivacyTestHelper::TestHelper

  def setup
    # Base class of the model
    @base_class = "Document"

    load_test_environment

    # fake out file upload
    @@documentdata ||= fixture_file_upload('/files/test.pdf', 'application/pdf')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :title => 'test document',
      :basket_id => '1',
      :uploaded_data => @@documentdata,
      :tag_list => ""
    }
  end

  def test_show_new_public_document_by_owner_and_admin
    id = create_record

    login_as(:admin)

    get :show, :id => id, :urlified_name => 'site'
    assert_equal id, assigns(:document).id
    assert_equal 1, assigns(:creator).id
    assert_equal 1, assigns(:last_contributor).id
    assert_not_nil assigns(:comments)
    assert_equal 0, assigns(:comments).size
    assert assigns(:show_privacy_chooser)
    assert_template 'documents/show'
    assert_response :success
  end

  def test_show_new_public_document_by_visitor
    id = create_record

    get :show, :id => id, :urlified_name => 'site'
    assert_equal id, assigns(:document).id
    assert_equal 1, assigns(:creator).id
    assert_equal 1, assigns(:last_contributor).id
    assert_not_nil assigns(:comments)
    assert_equal 0, assigns(:comments).size
    assert !assigns(:show_privacy_chooser)
    assert_template 'documents/show'
    assert_response :success
  end

  # Test that when a visitor requests a private document,
  # they are shown the most recent public version.
  def test_show_public
    # Create the first (public version)
    id = create_record(:private => false, :description => "Public version")

    # Create a new public version
    login_as(:admin)
    post :update, :id => id, :document => { :description => "Second public version" }, :urlified_name => 'site'
    assert_response :redirect

    # Create a new private version
    post :update, :id => id, :document => { :private => true, :description => "Private version" }, :urlified_name => 'site'
    assert_response :redirect

    # Reload the test environment so admin is no longer logged in..
    load_test_environment

    # Now to test..
    get :show, :id => id, :urlified_name => 'site'
    assert_response :success
    assert_template 'documents/show'
    assert_equal id, assigns(:document).id
    assert_equal 2, assigns(:document).version
    assert_equal "Second public version", assigns(:document).description
    assert !assigns(:document).private?
    assert !assigns(:show_privacy_chooser)
  end

  def test_show_public_with_no_public_version
    # Create the first (public version)
    id = create_record(:private => true, :description => "Private version")

    # Create a new private version
    login_as(:admin)
    post :update, :id => id, :document => { :private => true, :description => "Second private version" }, :urlified_name => 'site'
    assert_response :redirect

    # Reload the test environment so admin is no longer logged in..
    load_test_environment

    # Now to test..
    get :show, :id => id, :urlified_name => 'site'
    assert_response :success
    assert_template 'documents/show'
  end

  # Test that when an admin requests a private document,
  # they are shown the most recent version (regardless of privacy)
  def test_show_private
    # Create the first (public version)
    id = create_record(:private => false, :description => "Public version")

    # Create a new public version
    login_as(:admin)
    post :update, :id => id, :document => { :description => "Second public version" }
    assert_response :redirect

    # Create a new private version
    post :update, :id => id, :document => { :private => true, :description => "Private version" }
    assert_response :redirect

    # Reload the test environment so admin is no longer logged in..
    load_test_environment

    # Now to test..
    login_as(:admin)
    get :show, :id => id
    assert_response :success
    assert_template 'documents/show'
    assert_equal id, assigns(:document).id
    assert_equal 3, assigns(:document).version
    assert_equal "Private version", assigns(:document).description
    assert assigns(:document).private?

    # They should also be shown the privacy chooser..
    assert assigns(:show_privacy_chooser)
  end

  # Test that when an admin requests a private document,
  # with public=true, they are shown the most recent public version
  def test_show_private
    # Create the first (public version)
    id = create_record(:private => false, :description => "Public version")

    # Create a new public version
    login_as(:admin)
    post :update, :id => id, :document => { :description => "Second public version" }, :urlified_name => 'site', :private => "true"
    assert_response :redirect

    # Create a new private version
    post :update, :id => id, :document => { :private => true, :description => "Private version" }, :urlified_name => 'site'
    assert_response :redirect

    # Reload the test environment so admin is no longer logged in..
    load_test_environment

    # Now to test..
    login_as(:admin)
    get :show, :id => id, :urlified_name => 'site'
    assert_response :success
    assert_template 'documents/show'
    assert_equal id, assigns(:document).id
    assert_equal 2, assigns(:document).version
    assert_equal "Second public version", assigns(:document).description
    assert !assigns(:document).private?

    # They should also be shown the privacy chooser..
    assert assigns(:show_privacy_chooser)
  end

  def test_show_private_not_accessible
    id = create_record

    assert_raise ActionController::UnknownAction do
      get :show_private, :id => id, :urlified_name => 'site'
    end
  end

  def test_show_public_not_accessible
    id = create_record

    assert_raise ActionController::UnknownAction do
      get :show_public, :id => id, :urlified_name => 'site'
    end
  end

  def test_new
    # Login required..
    login_as(:admin)

    get :new, :urlified_name => 'site'
    assert_response :success
    assert_template 'documents/new'
    assert_not_nil assigns(:document)
    assert_kind_of Document, assigns(:document)
  end

  def test_create
    # Login required..
    login_as(:admin)

    post :create, :document => @new_model, :urlified_name => 'site'
    assert_not_nil assigns(:document)
    assert_not_nil assigns(:successful)

    assert_response :redirect
  end

  def test_edit
  end

  def test_update
  end

  def test_convert
  end

  def test_make_theme
  end

  def test_destroy
  end
end
