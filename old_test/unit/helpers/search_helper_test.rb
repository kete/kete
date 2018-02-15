require File.dirname(__FILE__) + '/../../test_helper'

class SearchHelperTest < ActionView::TestCase
  include ApplicationHelper

  def params
    {
      :urlified_name => 'site',
      :controller => 'search',
      :action => 'all'
    }
  end

  context "The other_results helper" do
    setup do
      @site_basket = Basket.site_basket
      @current_basket = @site_basket
    end

    should "correctly return an array of zoom types and their results size" do
      @current_class = 'Topic'
      @result_sets = { 'Topic' => [], 'WebLink' => [1, 2, 3] }
      assert_equal ['<a href="/en/site/all/web_links/" tabindex="1">3 Web links</a>'], other_results
    end
  end
end
