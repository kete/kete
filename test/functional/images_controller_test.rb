require File.dirname(__FILE__) + '/../test_helper'

class ImagesControllerTest < ActionController::TestCase

  # Load fixtures for users for login..
  fixtures :users

  include KeteTestFunctionalHelper
  include ItemPrivacyTestHelper::TestHelper

  def setup

    # Base class of the model
    @base_class = "Images" # No actual Images class, just used to load Controller

    load_test_environment

    # fake out file upload
    @@documentdata ||= fixture_file_upload('/files/white.jpg', 'image/jpeg')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_still_image  = { :title => 'test still image', :basket_id => Basket.find(:first) }
    @new_image_file   = { :uploaded_data => @@documentdata }

  end

  def test_new
    login_as :admin
    get :new, :urlified_name => 'site'
    assert_response :success
    assert_template 'new'
  end

  def test_create_populates_file_privacy_correctly_with_public
    login_as :admin
    post :create, :still_image => @new_still_image.merge({ :file_private => false }), :image_file => @new_image_file, :urlified_name => 'site'
    assert_not_nil assigns(:still_image)
    assert_not_nil assigns(:image_file)
    assert_equal 5, assigns(:still_image).image_files.size
    assert_equal false, assigns(:still_image).file_private?
    assert_equal false, assigns(:image_file).file_private?
    assigns(:still_image).image_files.each do |image|
      assert_equal false, image.file_private?
    end
    assert_response :redirect
    assert_redirected_to :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  def test_create_populates_file_privacy_correctly_with_private
    login_as :admin
    post :create, :still_image => @new_still_image.merge({ :file_private => true }), :image_file => @new_image_file, :urlified_name => 'site'
    assert_not_nil assigns(:still_image)
    assert_not_nil assigns(:image_file)
    assert_equal 5, assigns(:still_image).image_files.size
    assert_equal true, assigns(:still_image).file_private?
    assert_equal true, assigns(:image_file).file_private?
    # Walter McGinnis, resized images are now public
    # unless there is a private version of still image
    thumbnails_of(assigns(:still_image)).each do |image|
      assert_equal false, image.file_private
    end
    assert_equal true, original_of(assigns(:still_image)).file_private
    assert_response :redirect
    assert_redirected_to :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  def test_update_populates_file_privacy_correctly_from_public_to_private
    # Create some fixtures to test
    still_image = StillImage.create(@new_still_image.merge({ :file_private => false }))
    still_image.image_files.create(@new_image_file)
    still_image.image_files.first.thumbnails.each do |thumb|
      thumb.still_image_id = still_image.id
      thumb.save!
    end
    still_image.save
    still_image.reload

    # Update the still_image
    login_as :admin
    post :update, :id => still_image.id, :still_image => { :file_private => true }, :image_file => { :uploaded_data => "" }, :urlified_name => 'site'
    assert_not_nil assigns(:still_image)
    assert_equal 5, assigns(:still_image).image_files.size
    assert_equal false, assigns(:still_image).file_private?
    assigns(:still_image).image_files.each do |image|
      assert_equal false, image.file_private?
    end

    assert_response :redirect
    assert_redirected_to :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  def test_update_populates_file_privacy_correctly_from_private_to_public
    # Create some fixtures to test
    still_image = StillImage.create(@new_still_image.merge({ :file_private => true }))
    still_image.image_files.create(@new_image_file)
    still_image.image_files.first.thumbnails.each do |thumb|
      thumb.still_image_id = still_image.id
      thumb.save!
    end
    still_image.save
    still_image.reload

    # Update the still_image
    login_as :admin
    post :update, :id => still_image.id, :still_image => { :file_private => false }, :image_file => { :uploaded_data => "" }, :urlified_name => 'site'
    assert_not_nil assigns(:still_image)
    assert_equal 5, assigns(:still_image).image_files.size
    assert_equal false, assigns(:still_image).file_private?
    assigns(:still_image).image_files.each do |image|
      assert_equal false, image.file_private?
    end

    assert_response :redirect
    assert_redirected_to :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  private

    def thumbnails_of(still_image)
      original = still_image.original_file
      still_image.image_files.reject { |i| i.id == original.id }
    end

    def original_of(still_image)
      still_image.original_file
    end


end
