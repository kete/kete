require File.dirname(__FILE__) + '/integration_test_helper'

class RelatedToTopicTest < ActionController::IntegrationTest
  context "A Topic\'s related items" do

    setup do
      enable_production_mode
      add_john_as_regular_user
      login_as('john')
    end

    teardown do
      disable_production_mode
    end

    context "when a topic is added" do

      setup do
        @topic = new_topic(:title => 'Topic 1 Title')
      end

      should "have a related items section" do
        body_should_contain "Related Items"
      end

      related_classes = ZOOM_CLASSES - %w(Comment)
      related_classes.each do |class_name|
        should "have empty related #{class_name}" do
          body_should_contain "#{zoom_class_plural_humanize(class_name)} (0)"
        end
      end
    end
  end
end
