# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class TaggingTest < ActionController::IntegrationTest
  context "The quick add tag functionality" do
    setup do
      add_admin_as_super_user
      login_as('admin')
      Tag.destroy_all
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
            @item = new_web_link({ :url => "http://google.co.nz/#{rand * 100}" })
          when "Document"
            @item = new_document { attach_file "document_uploaded_data", "test.pdf" }
          else
            raise "ERROR: Unable to create item. Unknown item_class #{item_class}"
          end
          add_tags_to @item, ['tag 1', 'tag 2', 'tag 3']
        end
      end
    end

    context "when a tag is added" do
      setup do
        @topic = new_topic
        add_tags_to @topic, ['tag 0', 'tag 10', 'tag 20']
      end

      should "show up with contributor and version comment in history page" do
        visit "/site/topics/history/#{@topic.id}"
        body_should_contain '# 2' # revision 2
        body_should_contain 'Only tags added: tag 0, tag 10, tag 20'
      end

      context "and several are added in quick succession" do
        setup do
          add_tags_to @topic, ['tag 2', 'tag 12', 'tag 22']
          add_tags_to @topic, ['tag 4', 'tag 14', 'tag 24']
          add_tags_to @topic, ['tag 6', 'tag 16', 'tag 26']
          add_tags_to @topic, ['tag 8', 'tag 18', 'tag 28']
        end

        # checks that contributors/versions are in sync still
        should "all show up successfully in the history page" do
          visit "/site/topics/history/#{@topic.id}"
          body_should_contain '# 3'
          body_should_contain 'Only tags added: tag 2, tag 12, tag 22'
          body_should_contain '# 4'
          body_should_contain 'Only tags added: tag 4, tag 14, tag 24'
          body_should_contain '# 5'
          body_should_contain 'Only tags added: tag 6, tag 16, tag 26'
          body_should_contain '# 6'
          body_should_contain 'Only tags added: tag 8, tag 18, tag 28'
        end
      end

      context "and it contains wierd or other language chars" do
        setup do
          # escape chars, arabic, chinese, japanese, maori
          add_tags_to @topic, ['~ ! @ # $ % ^ * ( ) _ + { } | : " < > ? ` - = [ ] \\ ; \' . /']
          add_tags_to @topic, ['مرحبا']
          add_tags_to @topic, ['餵-家']
          add_tags_to @topic, ['こんにちは']
          add_tags_to @topic, ['āēīōū']
        end

        # we don't really need to test anything. If anything in add_tags_to fails, that's what we check
      end
    end

    context "when no tags are entered" do
      setup do
        @topic = new_topic
        add_tags_to @topic, [], false
      end

      should "redirect back to the item show page" do
        url_should_contain "/site/topics/show/#{@topic.id}"
        body_should_contain "There was an error adding the new tags to #{@topic.title}: No tags were entered."
      end
    end
  end

  private

  def add_tags_to(item, tags = [], check_successful = true)
    item_class = item.class.name
    controller = zoom_class_controller(item_class)
    item_type = item_class.underscore

    visit "/#{item.basket.urlified_name}/#{controller}/show/#{item.id}"
    fill_in "#{item_type}_tag_list", :with => tags.join(', ').to_s
    click_button 'add tag'
    if check_successful
      body_should_contain "The new tag(s) have been added to #{item.title}"
      tags.each { |tag| body_should_contain tag, :escape_chars => true }
    end
  end
end
