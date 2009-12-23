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

  context "The dc_metadata_for" do

    should "return correctly formatted XHTML" do
      bob = create_new_user :login => 'bob', :display_name => 'Bob Jones'
      jill = create_new_user :login => 'jill'

      item = Topic.create!({
        :title => 'Welcome',
        :short_summary => 'Information About the Site',
        :description => '<h2>What we do</h2>',
        :tag_list => 'about us, guide',
        :topic_type_id => TopicType.first,
        :basket_id => Basket.first
      })
      item.creator = bob

      data = <<-DATA
        <link href="http://purl.org/dc/terms/" rel="schema.DCTERMS" />
        <link href="http://purl.org/dc/elements/1.1/" rel="schema.DC" />
        <meta content="http://www.example.com/site/topics/show/#{item.id}-welcome" name="DC.identifier" scheme="DCTERMS.URI" />
        <meta content="Welcome" name="DC.title" />
        <meta content="about us" name="DC.subject" />
        <meta content="guide" name="DC.subject" />
        <meta content="Bob Jones" name="DC.creator" />
        <meta content="Kete" name="DC.publisher" />
        <meta content="Text" name="DC.type" />
      DATA

      assert_equal data.squish, dc_metadata_for(item).squish

      item.update_attributes!({
        :title => 'About Us'
      })
      item.add_as_contributor(jill)

      data = <<-DATA
        <link href="http://purl.org/dc/terms/" rel="schema.DCTERMS" />
        <link href="http://purl.org/dc/elements/1.1/" rel="schema.DC" />
        <meta content="http://www.example.com/site/topics/show/#{item.id}-about-us" name="DC.identifier" scheme="DCTERMS.URI" />
        <meta content="About Us" name="DC.title" />
        <meta content="about us" name="DC.subject" />
        <meta content="guide" name="DC.subject" />
        <meta content="Bob Jones" name="DC.creator" />
        <meta content="Kete" name="DC.publisher" />
        <meta content="Text" name="DC.type" />
      DATA

      assert_equal data.squish, dc_metadata_for(item).squish
    end

  end

end
