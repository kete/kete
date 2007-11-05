require File.dirname(__FILE__) + '/../test_helper'

class AudioRecordingTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "AudioRecording"

    # fake out file upload
    audiodata = fixture_file_upload('/files/Sin1000Hz.mp3', 'audio/mpeg')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test audio recording',
      :basket => Basket.find(:first),
      :uploaded_data => audiodata }
    @req_attr_names = %w(title) # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper

  # only inlude on one model
  include FriendlyUrlsTestUnitHelper

end
