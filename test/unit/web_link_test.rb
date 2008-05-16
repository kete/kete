require File.dirname(__FILE__) + '/../test_helper'

class WebLinkTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "WebLink"
    
    # Extend the base class so test files from attachment_fu get put in the 
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :title => 'test item',
      :basket => Basket.find(:first),
      :url => "http://kete.net.nz/about/" }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title url)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w(url)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  # include ItemPrivacyTestHelper::Tests::FilePrivate
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  
end

