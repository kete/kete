require File.dirname(__FILE__) + '/../test_helper'

class VideoTest < Test::Unit::TestCase
  # fixtures preloaded
  def setup
    @base_class = "Video"

    # fake out file upload
    videodata = fixture_file_upload('/files/teststrip.mpg', 'video/mpeg')

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test video',
      :basket => Basket.find(:first),
      :uploaded_data => videodata }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper

  # TODO: attachment_attributes_valid?

end
