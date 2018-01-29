require File.dirname(__FILE__) + '/integration_test_helper'

::ActionController::UrlWriter.module_eval do
  default_url_options[:host] = SITE_NAME
end

class RssTest < ActionController::IntegrationTest
  # some pretty massive holes in test coverage here!!!
  # TODO: test comments being added and having proper rss
  # TODO: add contributed by, related to, and tagged tests
  # TODO: add privacy tests
  # after you start adding these TODOs, you'll immediately want to DRY up this testing
  context "An rss feed with items" do
    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    ITEM_CLASSES.each do |item_class|
      should "still have a feed for all class #{item_class}" do
        item_type = item_class.underscore
        controller = zoom_class_controller(item_class)
        case item_class
        when "Topic"
          @item = new_topic
        when "StillImage"
          @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        when "AudioRecording"
          @item = new_audio_recording { attach_file "audio_recording_uploaded_data", "Sin1000Hz.mp3" }
        when "Video"
          @item = new_video { attach_file "video_uploaded_data", "teststrip.mpg", "video/mpeg" }
        when "WebLink"
          @item = new_web_link(:url => "http://google.co.nz/#{rand * 100}")
          @item_type = 'web links'
        when "Document"
          @item = new_document { attach_file "document_uploaded_data", "test.pdf" }
        else
          raise "ERROR: Unable to create item. Unknown item_class #{item_class}"
        end

        visit "/site/all/#{controller}/rss.xml"
        body_should_contain "Latest 50 Results in #{@item_type || controller}"
        body_should_contain @item.title
      end

      should "still have a feed for all combined" do
        item_type = item_class.underscore
        controller = zoom_class_controller(item_class)
        case item_class
        when "Topic"
          @item = new_topic
        when "StillImage"
          @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        when "AudioRecording"
          @item = new_audio_recording { attach_file "audio_recording_uploaded_data", "Sin1000Hz.mp3" }
        when "Video"
          @item = new_video { attach_file "video_uploaded_data", "teststrip.mpg", "video/mpeg" }
        when "WebLink"
          @item = new_web_link(:url => "http://google.co.nz/#{rand * 100}")
          @item_type = 'web links'
        when "Document"
          @item = new_document { attach_file "document_uploaded_data", "test.pdf" }
        else
          raise "ERROR: Unable to create item. Unknown item_class #{item_class}"
        end

        # now should have a combined rss that contains the same item
        visit "/site/all/combined/rss.xml"
        body_should_contain "Latest 50 Results in combined"
        body_should_contain @item.title
      end
    end

    should "escape title and short summary" do
      @item = new_topic(:title => 'This <or> That', :short_summary => 'This <and> that')
      visit "/site/all/topics/rss.xml"
      body_should_contain "Latest 50 Results in topics"
      body_should_contain @item.title
      body_should_contain 'This that'
      body_should_not_contain 'This <and> that' # the source shouldn't have the uncleaned short_summary
    end

    should "escape image tag" do
      @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      visit "/site/all/images/rss.xml"
      body_should_contain "Latest 50 Results in images"
      # this test is failing because of newline in the body before src and no other reason
      # TODO: fix
      image_tag = "<img alt=\"Image Title. \" height=\"50\" src=\"http://www.example.com#{@item.small_sq_file.public_filename}"
      logger = RAILS_DEFAULT_LOGGER
      logger.info("what is body: " + response.body.inspect)
      body_should_contain image_tag
    end

    should "be able to be limited using count" do
      @topic1 = new_topic :title => 'Topic 1'
      @topic2 = new_topic :title => 'Topic 2'

      visit "/site/all/topics/rss.xml"
      body_should_contain 'Topic 2'
      body_should_contain 'Topic 1'

      visit "/site/all/topics/rss.xml?count=1"
      body_should_contain 'Topic 2'
      body_should_not_contain 'Topic 1'

      visit "/site/all/topics/rss.xml?count=1&page=2"
      body_should_contain 'Topic 1'
      body_should_not_contain 'Topic 2'
    end
  end
end
