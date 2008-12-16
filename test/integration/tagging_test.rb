require File.dirname(__FILE__) + '/integration_test_helper'

class TaggingTest < ActionController::IntegrationTest

  context "The quick add tag functionality" do

    setup do
      add_admin_as_super_user
      login_as('admin')
    end

    context "when Javascript is off" do

      ['topic', 'still_image', 'audio_recording', 'video', 'web_link', 'document'].each do |item_type|
        should "still function properly for #{item_type}" do
          zoom_class = item_type.classify
          case zoom_class
          when "Topic"
            controller = 'topics'
            @item = new_topic
          when "StillImage"
            controller = 'images'
            @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
          when "AudioRecording"
            controller = 'audio'
            @item = new_audio_recording { attach_file "audio_recording_uploaded_data", "Sin1000Hz.mp3" }
          when "Video"
            controller = 'video'
            @item = new_video { attach_file "video_uploaded_data", "teststrip.mpg", "video/mpeg" }
          when "WebLink"
            controller = 'web_links'
            @item = new_web_link({ :url => "http://google.co.nz/#{rand() * 100}" })
          when "Document"
            controller = zoom_class.tableize
            @item = new_document { attach_file "document_uploaded_data", "test.pdf" }
          else
            raise "ERROR: Unable to create item. Unknown zoom_class #{zoom_class}"
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