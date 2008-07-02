require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helper')

DEFAULT_CONTENT_LICENSE = '2'

class ActsAsLicensedHelperTest < ActionView::TestCase
  
  def test_should_be_able_to_loop_over_licenses
    available_licenses do
      #assert !license.name.empty?
      #this might be hard to test since anything we put in this block is excuted within helpers loop (thus the helpers module), not this test class
    end
  end
  
  def test_should_not_find_any_licenses
    assert_equal false, licenses_are_available?
  end
  
  def test_should_find_licenses
    should_load_nz_licenses
    assert_equal true, licenses_are_available?
  end
    
  def test_return_appropriate_default_content_license
    assert_not_nil configured_default_license
    assert_equal 2, configured_default_license
  end
  
  #
  # RAKE TASKS (problem with including rake task file itself, so we'll just call the function used in the rake file
  #
  def should_load_nz_licenses
    assert_difference 'License.count', 4 do
      License.import_from_yaml('nz_default_creative_commons_licenses.yml', false)
    end
  end
  
end
