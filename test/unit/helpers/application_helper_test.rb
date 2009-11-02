require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase

  context "The title_with_context" do

    should "only contain the site name in the right circumstances" do
      @title = "Topic Page"
      @site_basket = Basket.site_basket

      @current_basket = @site_basket
      assert_equal 'Topic Page - Kete', title_with_context

      @current_basket = Basket.about_basket
      assert_equal 'Topic Page - About - Kete', title_with_context
    end

  end

end
