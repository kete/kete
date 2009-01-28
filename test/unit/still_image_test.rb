require File.dirname(__FILE__) + '/../test_helper'

class StillImageTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "StillImage"
    
    # Extend the base class so test files from attachment_fu get put in the 
    # tmp directory, and not in the development/production directories.
    # eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test item',
      :basket_id => Basket.find(:first) }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)
    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )
    
    # ImageFile fixture for testing
    documentdata = fixture_file_upload('/files/white.jpg', 'image/jpeg')
    @new_image_file = { :uploaded_data => documentdata }
    
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext

  # TODO: more testing of image_file population?
  # TODO: find_with
  
  def test_is_versioned
    still_image = StillImage.create(@new_model)
    assert_not_nil still_image.versions
    assert_equal still_image.versions.size, 1
    assert_equal still_image.versions.find_by_version(1).title, still_image.title
  end
  
  def test_associations_work
    still_image = StillImage.create(@new_model.merge({ :file_private => true }))
    still_image.image_files.create(@new_image_file.merge(:file_private => still_image.file_private))
    still_image.image_files.first.thumbnails.each do |thumb|
      thumb.still_image_id = still_image.id
      thumb.save!
    end
    still_image.reload
    
    # Check the scenario is in place
    assert_valid still_image
    still_image.image_files.each { |i| assert_valid i }
    assert_equal 5, still_image.image_files.size
    assert_kind_of ImageFile, original_of(still_image)
    assert_equal 4, thumbnails_of(still_image).size
    assert still_image.respond_to?(:original_file)
    assert still_image.original_file.respond_to?(:update_attributes)
  end
  
  def test_updates_image_file_locations_on_update
    
    # Create the scenario
    still_image = StillImage.create(@new_model.merge({ :file_private => true }))
    still_image.image_files.create(@new_image_file.merge(:file_private => still_image.file_private))
    still_image.image_files.first.thumbnails.each do |thumb|
      thumb.still_image_id = still_image.id
      thumb.save!
    end
    still_image.reload
    
    # Check the scenario is in place
    assert_valid still_image
    still_image.image_files.each { |i| assert_valid i }
    assert_equal 5, still_image.image_files.size
    assert_kind_of ImageFile, original_of(still_image)
    assert_equal 4, thumbnails_of(still_image).size

    # Check that original and thumbnails are private after create
    assert_equal true, still_image.file_private?
    assert_equal true, original_of(still_image).file_private?
    thumbnails_of(still_image).each do |image|
      assert_equal true, image.file_private?
    end
    
    # Update everything to public
    still_image.update_attributes!({ :file_private => false })
    still_image.reload
    assert_equal false, still_image.file_private?
    assert_equal false, original_of(still_image).file_private?
    thumbnails_of(still_image).each do |image|
      assert_equal false, image.file_private?
    end
    
    # Try and change everything to private again and check that it
    # does not work for original or thumbnails.
    still_image.update_attributes!({ :file_private => true })
    still_image.reload
    assert_equal false, still_image.file_private?
    assert_equal false, original_of(still_image).file_private?
    thumbnails_of(still_image).each do |image|
      assert_equal false, image.file_private?
    end
    
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
