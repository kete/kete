require File.dirname(__FILE__) + '/integration_test_helper'

class TaggingTest < ActionController::IntegrationTest

  context "The quick add tag functionality" do

    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    context "when Javascript is off" do

      ITEM_CLASSES.each do |item_class|
        should "still function properly for #{item_class}" do
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
            @item = new_web_link({ :url => "http://google.co.nz/#{rand() * 100}" })
          when "Document"
            @item = new_document { attach_file "document_uploaded_data", "test.pdf" }
          else
            raise "ERROR: Unable to create item. Unknown item_class #{item_class}"
          end
          visit "/site/#{controller}/show/#{@item.id}"
          fill_in "#{item_type}_tag_list", :with => 'tag 1,tag 2,tag 3'
          click_button 'add tag'
          body_should_contain 'tag 1'
          body_should_contain 'tag 2'
          body_should_contain 'tag 3'
        end
      end

    end

    # Needs Selenium testing available
    #context "when Javascript is on" do
    #  should "function without a page load" do
    #  end
    #end

  end

end