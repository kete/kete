require File.dirname(__FILE__) + '/../test_helper'

class ImageFilesTest < ActiveSupport::TestCase
  # fixtures preloaded

  # skipping, almost exclusively declaritive
  # its testing should be handled by ActiveRecord and plugins
  # and StillImage

  def setup
    @base_class = "ImageFile"

    # Extend the base class so test files from attachment_fu get put in the
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # fake out file upload
    @@documentdata ||= fixture_file_upload('/files/white.jpg', 'image/jpeg')

    options_for_still_image = { :title => 'test still image', :basket => Basket.find(:first) }
    @public_still_image = StillImage.create(options_for_still_image.merge({ :file_private => false }))
    @private_still_image = StillImage.create(options_for_still_image.merge({ :file_private => true }))

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :uploaded_data => @@documentdata, :still_image_id => @public_still_image.id }

    # Name of the folder we expect files to be saved to
    @uploads_folder = 'image_files'
  end

  # load in sets of tests and helper methods
  include ItemPrivacyTestHelper::TestHelper

  # Test attachment_fu overrides
  def test_attachment_fu_uses_correct_path_prefix
    image_file = ImageFile.create(@new_model.merge({ :file_private => false }))
    assert_match(attachment_fu_test_path("public", @uploads_folder), image_file.full_filename)
    assert File.exist?(image_file.full_filename)
    assert image_file.valid?
  end

  def test_attachment_fu_uses_correct_path_prefix2
    image_file2 = ImageFile.create(@new_model.merge({ :file_private => true }))
    assert_match(attachment_fu_test_path("private", @uploads_folder), image_file2.full_filename)
    assert File.exist?(image_file2.full_filename)
    assert image_file2.valid?
  end

  def test_attachment_fu_does_not_move_files_when_going_from_public_to_private
    image_file = ImageFile.create(@new_model.merge({ :file_private => false }))
    assert_match(attachment_fu_test_path("public", @uploads_folder), image_file.full_filename)
    assert File.exist?(image_file.full_filename)
    assert image_file.valid?
    old_filename = image_file.full_filename
    id = image_file.id

    image_file = ImageFile.find(id)
    image_file.still_image.update_attributes({ :file_private => true })
    assert_match(attachment_fu_test_path("public", @uploads_folder), image_file.full_filename)
    assert File.exist?(image_file.full_filename), "File is not where we expected. Should be at #{image_file.full_filename} but is not present."
    assert_equal old_filename, image_file.full_filename
    assert image_file.valid?
  end

  def test_attachment_fu_moves_files_to_correct_path_when_going_from_private_to_public
    image_file = ImageFile.create(@new_model.merge({ :file_private => true }))
    assert_equal true, image_file.file_private?
    assert_match(attachment_fu_test_path("private", @uploads_folder), image_file.full_filename)
    assert File.exist?(image_file.full_filename)
    assert image_file.valid?
    old_filename = image_file.full_filename
    id = image_file.id

    image_file = ImageFile.find(id)
    image_file.still_image.update_attributes({ :file_private => false })

    # Image file modified by callback on StillImage, reload
    image_file.reload

    assert_equal false, image_file.file_private?
    assert_match(attachment_fu_test_path("public", @uploads_folder), image_file.full_filename)
    assert File.exist?(image_file.full_filename), "File is not where we expected. Should be at #{image_file.full_filename} but is not present."
    assert !File.exist?(old_filename), "File is not where we expected. Should NOT be at #{old_filename} but IS present."
    assert image_file.valid?
  end

  def test_attachment_path_prefix
    image_file = ImageFile.create(@new_model.merge({ :file_private => true }))
    assert_equal image_file.send(:attachment_path_prefix), "private"

    image_file = ImageFile.create(@new_model.merge({ :file_private => false }))
    assert_equal image_file.send(:attachment_path_prefix), "public"
  end

  def test_attachment_full_filename
    image_file = ImageFile.create(@new_model.merge({ :file_private => true }))
    assert_equal File.join(RAILS_ROOT, "tmp", "attachment_fu_test", "private", "image_files", *image_file.send(:partitioned_path, image_file.send(:thumbnail_name_for, nil))), image_file.full_filename

    image_file = ImageFile.create(@new_model.merge({ :file_private => false }))
    assert_equal File.join(RAILS_ROOT, "tmp", "attachment_fu_test", "public", "image_files", *image_file.send(:partitioned_path, image_file.send(:thumbnail_name_for, nil))), image_file.full_filename
  end

  def test_basket_returns_nil_if_no_still_image
    image = ImageFile.create(@new_model.merge({ :file_private => false, :still_image_id => nil }))
    assert_nil image.basket
  end

  def test_basket_returns_basket_if_still_image
    image = ImageFile.create(@new_model.merge({ :file_private => false }))
    assert_not_nil image.basket
    assert_kind_of Basket, image.basket
  end

  context "An Image file" do
    should "respond to bigger_than? method when given max dimensions, with true or false if it fits within bounds of dimensions" do
      image = ImageFile.create(@new_model)
      assert image.respond_to?(:bigger_than?)

      # nil means no maximum dimension
      dimensions = { :height => nil, :width => nil }
      assert !image.bigger_than?(dimensions)

      dimensions = { :height => 100, :width => 100 }
      assert !image.bigger_than?(dimensions)

      dimensions = { :height => 56, :width => 56 }
      assert !image.bigger_than?(dimensions)

      dimensions = { :height => 50, :width => 50 }
      assert image.bigger_than?(dimensions)
    end
  end
end
