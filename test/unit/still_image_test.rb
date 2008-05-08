require File.dirname(__FILE__) + '/../test_helper'

class StillImageTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "StillImage"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test still image',
      :basket => Basket.find(:first) }

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

  # TODO: more testing of image_file population?
  # TODO: find_with
end
