require File.dirname(__FILE__) + '/integration_test_helper'

class RelatedToTopicTest < ActionController::IntegrationTest
  context "A Topic\'s related items" do

    setup do
      enable_production_mode
      add_john
      login_as('john')
    end

    teardown do
      disable_production_mode
    end

    context "when a topic is added" do

      setup do
        @topic = new_topic({ :title => 'Topic 1 Title',
                             :description => 'Topic 1 Description' }, @@cache_basket)
      end

      should "have a related items section" do
        body_should_contain "Related Items"
      end

    end

  end

end
