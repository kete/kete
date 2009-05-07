require File.dirname(__FILE__) + '/../test_helper'

class StillImageTest < ActiveSupport::TestCase
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
    @@documentdata ||= fixture_file_upload('/files/white.jpg', 'image/jpeg')
    @new_image_file = { :uploaded_data => @@documentdata }

  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include RelatedItemsTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext
  include ItemPrivacyTestHelper::Tests::MovingItemsBetweenBasketsWithDifferentPrivacies

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
    assert still_image.valid?
    still_image.image_files.each { |i| assert i.valid? }
    assert_equal 5, still_image.image_files.size
    assert_kind_of ImageFile, original_of(still_image)
    assert_equal 4, thumbnails_of(still_image).size
    assert still_image.respond_to?(:original_file)
    assert still_image.original_file.respond_to?(:update_attributes)
  end

  def test_updates_image_file_locations_on_update

    # Create the scenario
    still_image = new_still_image({ :file_private => true }, { :file_private => true })

    # Check that original is private after create
    file_private_should_be(true, still_image)

    # Update everything to public
    still_image.update_attributes!({ :file_private => false })
    still_image.reload
    file_private_should_be(false, still_image)

    # Change everything to private again and check that it does not work
    still_image.update_attributes!({ :file_private => true })
    still_image.reload
    file_private_should_be(false, still_image)

    #
    # Thumbnails are handled by still image private setting, not
    # still image file_private setting, so add seperate tests for that
    #

    # setup private still image
    still_image = new_still_image({ :private => true }, { :item_private => true })

    # Check that original and thumbnails are private after create
    thumbnails_of(still_image).each do |image|
      assert_equal true, image.file_private?
    end

    # Update everything to public
    still_image.update_attributes!({ :private => false })
    still_image.reload
    thumbnails_of(still_image).each do |image|
      assert_equal false, image.file_private?
    end

    # Try and change everything to private again and check that it
    # does not work for original or thumbnails.
    still_image.update_attributes!({ :private => true, :file_private => true })
    still_image.reload
    thumbnails_of(still_image).each do |image|
      assert_equal false, image.file_private?
    end

  end

  def test_should_have_relation_and_user_when_in_portraits
    user = User.first
    new_image_with_creator user
    UserPortraitRelation.new_portrait_for(user, @still_image)
    @still_image.reload

    assert_not_nil @still_image.user_portrait_relation
    assert_not_nil @still_image.portrayed_user
    assert_kind_of User, @still_image.portrayed_user
    assert_equal User.first, @still_image.portrayed_user
  end

  def test_should_check_whether_user_is_image_uploader
    user = User.first
    new_image_with_creator user

    assert_equal true, @still_image.created_by?(user)
  end

  private

    def new_still_image(still_image_options, image_file_options)
      still_image = StillImage.create(@new_model.merge(still_image_options))
      still_image.image_files.create(@new_image_file.merge(image_file_options))
      still_image.image_files.first.thumbnails.each do |thumb|
        thumb.still_image_id = still_image.id
        thumb.save!
      end
      still_image.reload
      assert_valid_still_image(still_image)
      still_image
    end

    def assert_valid_still_image(still_image)
      assert_valid still_image
      still_image.image_files.each { |i| assert_valid i }
      assert_equal 5, still_image.image_files.size
      assert_kind_of ImageFile, original_of(still_image)
      assert_equal 4, thumbnails_of(still_image).size
    end

    def thumbnails_of(still_image)
      original = still_image.original_file
      still_image.image_files.reject { |i| i.id == original.id }
    end

    def original_of(still_image)
      still_image.original_file
    end

    def file_private_should_be(boolean, still_image)
      assert_equal boolean, still_image.file_private?
      assert_equal boolean, original_of(still_image).file_private?
    end

    def new_image_with_creator(user)
      @still_image = StillImage.create(@new_model)
      @still_image.creator = user
      @still_image.save
    end
end
