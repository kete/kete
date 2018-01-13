require File.dirname(__FILE__) + '/../test_helper'

class AudioRecordingTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @base_class = "AudioRecording"

    # Extend the base class so test files from attachment_fu get put in the
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # fake out file upload
    @@audiodata ||= fixture_file_upload('/files/Sin1000Hz.mp3', 'audio/mpeg')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :title => 'test item',
      :basket => Basket.find(:first),
      :uploaded_data => @@audiodata
    }
    @req_attr_names = %w(title) # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w() # name of fields that cannot be a duplicate, e.g. %(name description)

    # Name of the folder we expect files to be saved to
    @uploads_folder = 'audio'
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include RelatedItemsTestUnitHelper

  # only include in basket and audio unit tests
  include FriendlyUrlsTestUnitHelper

  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::FilePrivate
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext
  include ItemPrivacyTestHelper::Tests::MovingItemsBetweenBasketsWithDifferentPrivacies

  include MergeTestUnitHelper
end
