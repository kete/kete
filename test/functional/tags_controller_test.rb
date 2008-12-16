require File.dirname(__FILE__) + '/../test_helper'

class TagsControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "Tags"
    load_test_environment
  end

  def test_rss_feed_accessible_logged_out
    logout
    get :rss, :urlified_name => 'site', :controller => 'list', :action => 'rss'
    assert_response :success
    assert_not_nil(:tags)
  end
  
  def test_rss_feed_accessible_logged_in
    login_as(:admin)
    get :rss, :urlified_name => 'site', :controller => 'list', :action => 'rss'
    assert_response :success
    assert_not_nil(:tags)
  end

end
