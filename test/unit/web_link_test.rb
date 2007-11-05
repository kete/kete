require File.dirname(__FILE__) + '/../test_helper'

class WebLinkTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "WebLink"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test web link',
      :basket => Basket.find(:first),
      :url => 'http://kete.net.nz/about/' }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title url)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w(url)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper

end

