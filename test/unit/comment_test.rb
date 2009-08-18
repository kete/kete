require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
  # fixtures preloaded
  def setup
    @base_class = "Comment"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { 
      :title => 'test comment',
      :description => 'test',
      :basket => Basket.find(:first),
      :commentable_id => 1,
      :commentable_type => 'Topic' 
    }
    @req_attr_names = %w(title description) # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  end

  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
