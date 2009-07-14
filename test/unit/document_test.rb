require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Document"

    # Extend the base class so test files from attachment_fu get put in the
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # fake out file upload
    @@documentdata ||= fixture_file_upload('/files/test.pdf', 'application/pdf')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :title => 'test item',
      :basket => Basket.find(:first),
      :uploaded_data => @@documentdata
    }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )

    # Name of the folder we expect files to be saved to
    @uploads_folder = 'documents'
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include RelatedItemsTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::FilePrivate
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext
  include ItemPrivacyTestHelper::Tests::MovingItemsBetweenBasketsWithDifferentPrivacies

  # TODO: attachment_attributes_valid?

  # Test attachment_fu overrides

  def test_not_fully_moderated_add_succeeds
    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 1
    assert_equal 1, model.version
    # no flags on version
    assert_equal 0, model.versions.find_by_version(1).tags.size
  end

  def test_fully_moderated_add_flags_version_as_pending_and_creates_blank_current_version
    # make the basket require moderation
    Basket.find(:first).settings[:fully_moderated] = true

    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 2 since a new blank version should be automatically added
    # it shouldn't have any flags on the live version
    assert_equal 2, model.version
    assert_equal BLANK_TITLE, model.title
    assert_equal 0, model.versions.find_by_version(model.version).tags.size

    # first version should be flagged as pending
    assert model.versions.find_by_version(1).tags.include?(Tag.find_by_name(PENDING_FLAG))
  end

  def test_fully_moderated_basket_but_excepted_class_add_succeeds
    # make the basket require moderation
    @basket = Basket.find(:first)
    @basket.settings[:fully_moderated] = true

    # but make this class be listed as free of moderation
    @basket.settings[:moderated_except] = [@base_class]

    model = Module.class_eval(@base_class).new @new_model
    model.save
    model.reload

    # version should be 1
    assert_equal 1, model.version
    # no flags on version
    assert_equal 0, model.versions.find_by_version(1).tags.size
  end

  def test_acts_as_taggable_abides_by_separate_contexts_when_deleting

    # This test case fails due to a bug in acts_as_taggable_on

    # Create a new document to test with
    document = Module.class_eval(@base_class).new @new_model
    document.save!

    # Add some tags on different contexts
    ["a", "b", "c"].each do |tag|
      document.private_tag_list << tag
    end

    ["x", "y", "z", "c"].each do |tag|
      document.public_tag_list << tag
    end

    # Save anc check tags exist as we expect
    document.save
    document.reload

    assert_equal ["a", "b", "c"], document.private_tag_list.sort
    assert_equal ["c", "x", "y", "z"], document.public_tag_list.sort

    # Delete a common tag and check the deletion was only in the specified context.
    document.save
    document.reload

    document.public_tag_list.delete("c")
    document.save

    # Reload correctly
    document = nil
    document = Document.last

    assert_equal ["a", "b", "c"], document.tags_on(:private_tags).map(&:name).sort
    assert_equal ["x", "y", "z"], document.tags_on(:public_tags).map(&:name).sort
  end

end
