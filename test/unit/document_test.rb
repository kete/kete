require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < Test::Unit::TestCase
  # fixtures preloaded
  
  def setup
    @base_class = "Document"
    
    # Extend the base class so test files from attachment_fu get put in the 
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # fake out file upload
    documentdata = fixture_file_upload('/files/test.pdf', 'application/pdf')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test item',
      :basket => Basket.find(:first),
      :uploaded_data => documentdata }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::FilePrivate
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration

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
  


end
