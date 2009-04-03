require File.dirname(__FILE__) + '/../test_helper'

class SearchSourceTest < ActiveSupport::TestCase

  should_require_attributes :title
  should_require_attributes :source_type
  should_require_attributes :base_url
  should_require_attributes :limit

  context "The Search Source model" do

    should "contain a class var of acceptable source types" do
      assert_equal %w{ feed }, SearchSource.acceptable_source_types
    end

  end

end
