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

      # only relevant to related classes that have attachments
      attachable_classes = related_classes - %w(WebLink Topic)

      related_classes.each do |class_name|
        context "the related #{class_name} subsection" do
          should "be empty to start" do
            body_should_contain "#{zoom_class_plural_humanize(class_name)} (0)"
          end

          should_eventually "be able to create related #{class_name}"
          should_eventually "be able to link existing related #{class_name}"
          should_eventually "be able to unlink related #{class_name}"
          should_eventually "be able to restore unlinked related #{class_name}"

          if attachable_classes.include?(class_name)
            should_eventually "be able to upload a zip file of related #{class_name.tableize}"
          end

          should_eventually "not display links to items with no public version"

        end
      end
    end
  end
end

