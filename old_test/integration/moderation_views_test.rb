require File.dirname(__FILE__) + '/integration_test_helper'

class ModerationViewsTest < ActionController::IntegrationTest
  context "Topic with multiple versions as a regular user" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      # Create a test item
      @item = new_topic
      update_item(@item)
      update_item(@item, :title => "Homepage Title Updated Again")
    end

    should "be able to visit item page" do
      visit "/site/topics/show/#{@item.id}"
      body_should_contain "Homepage Title Updated Again"
      body_should_contain "History"
    end

    should "be able to visit history page for item" do
      visit "/site/topics/history/#{@item.id}"
      body_should_contain "Revision History: Homepage Title Updated Again"
      body_should_contain "Back to live"
      1.upto(3) do |i|
        body_should_contain "# #{i}"
      end
    end

    should "be able to visit previews for each version of an item" do
      1.upto(2) do |i|
        visit "/site/topics/preview/#{@item.id}?version=#{i}"
        body_should_contain "Preview revision ##{i}: view live"
        body_should_contain "Topic: #{@item.versions.find_by_version(i).title}"
        body_should_contain @item.versions.find_by_version(i).description
        body_should_contain "Actions"
        body_should_not_contain I18n.t('topics.preview_actions.make_live')
        body_should_not_contain I18n.t('topics.preview_actions.reject')
      end
    end

    context "as a super user" do
      setup do
        add_mac_as_super_user
        login_as("mac")
      end

      should "be able to visit previews for each version of an item and see controls" do
        1.upto(2) do |i|
          visit "/site/topics/preview/#{@item.id}?version=#{i}"
          body_should_contain "Preview revision ##{i}: view live"
          body_should_contain "Topic: #{@item.versions.find_by_version(i).title}"
          body_should_contain @item.versions.find_by_version(i).description
          body_should_contain "Actions"

          # Should have controls for making versions live or not
          body_should_contain I18n.t('topics.preview_actions.make_live')
          body_should_contain I18n.t('topics.preview_actions.reject')
        end
      end
    end
  end

  context "Topic with multiple versions as a super user" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_super_user
      login_as('grant')

      # Create a test item
      @item = new_topic
      update_item(@item)
      update_item(@item, :title => "Homepage Title Updated Again")
    end

    should "be able to visit item page" do
      visit "/site/topics/show/#{@item.id}"
      body_should_contain "Homepage Title Updated Again"
      body_should_contain "History"
    end

    should "be able to visit history page for item" do
      visit "/site/topics/history/#{@item.id}"
      body_should_contain "Revision History: Homepage Title Updated Again"
      body_should_contain "Back to live"
      1.upto(3) do |i|
        body_should_contain "# #{i}"
      end
    end
  end

  context "Image with multiple versions" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      @image = new_still_image do
        attach_file "image_file_uploaded_data", "white.jpg"
      end

      update_item(@image, :title => "New image updated")
      update_item(@image, :title => "New image updated again")
    end

    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@image, 'images', 'StillImage')
    end
  end

  context "Video with multiple versions" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      @video = new_video do
        attach_file "video[uploaded_data]", "teststrip.mpg", "video/mpeg"
      end

      update_item(@video, :title => "New video updated")
      update_item(@video, :title => "New video updated again")
    end

    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@video, 'video', 'Video')
    end
  end

  context "Audio with multiple versions" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      @audio = new_audio_recording do
        attach_file "audio_recording[uploaded_data]", "Sin1000Hz.mp3" #, "audio/mpeg"
      end

      update_item(@audio, :title => "New audio updated")
      update_item(@audio, :title => "New audio updated again")
    end

    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@audio, 'audio', 'AudioRecording')
    end
  end

  context "Document with multiple versions" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      @document = new_document do
        attach_file "document[uploaded_data]", "test.pdf" #, "application/pdf"
      end

      update_item(@document, :title => "New document updated")
      update_item(@document, :title => "New document updated again")
    end

    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@document, 'documents', 'Document')
    end
  end

  context "Weblink with multiple versions" do
    setup do
      # Ensure a user account to log in with is present
      add_grant_as_regular_user
      login_as('grant')

      @weblink = new_web_link do
        fill_in "web_link[url]", :with => "http://www.google.com/"
      end

      update_item(@weblink, :title => "New web_link updated")
      update_item(@weblink, :title => "New web_link updated again")
    end

    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@weblink, 'web_links', 'WebLink')
    end

    teardown do
      @weblink.destroy unless @weblink.new_record?
    end
  end

  context "The ability to restrict revisions upon moderation" do
    setup do
      login_as(:admin)
      add_sally_as_moderator_to @@site_basket
      add_grant_as_regular_user

      @topic = new_topic(:title => 'Version 1')
      @topic = update_item(@topic, :title => 'Version 2')
      visit "/site/topics/preview/#{@topic.id}?version=1"
      click_link I18n.t('topics.preview_actions.reject')
      fill_in 'message_', :with => 'Testing'
      check 'restricted'
      click_button 'Reject'
      body_should_contain 'This version of this Topic has been rejected.'
    end

    should "work as expected and block access to moderators or above" do
      %w{ admin sally }.each do |user|
        login_as(user)
        visit "/site/topics/history/#{@topic.id}"
        body_should_contain 'preview' # rev 1
        body_should_contain 'current' # rev 2
        visit "/site/topics/preview/#{@topic.id}?version=1"
        body_should_contain 'Preview revision #1'
      end

      login_as(:grant)
      visit "/site/topics/history/#{@topic.id}"
      body_should_contain 'restricted' # rev 1
      body_should_contain 'current'    # rev 2
      visit "/site/topics/preview/#{@topic.id}?version=1"
      # should get redirected, as this is permission denied since it is restricted
      assert !response.ok?
    end
  end

  context "The ability to review revisions" do
    setup do
      login_as(:admin)
      add_grant_as_regular_user

      @topic = new_topic(:title => 'Version 1')
      @topic = update_item(@topic, :title => 'Version 2')
      visit "/site/topics/preview/#{@topic.id}?version=1"
      click_link 'Mark as reviewed'
      fill_in 'message_', :with => 'Testing'
      click_button 'Review'
      body_should_contain 'This version of the Topic has been marked as reviewed.'
    end

    should "not reject/restrict the revision, make the revision live, or create a new version" do
      visit "/site/topics/preview/#{@topic.id}?version=1"
      body_should_contain 'Version 1'

      visit "/site/topics/show/#{@topic.id}"
      body_should_contain 'Version 2'

      visit "/site/topics/history/#{@topic.id}"
      body_should_contain 'reviewed by moderator'
      body_should_contain '# 1'
      body_should_contain '# 2'
      body_should_not_contain '# 3'

      login_as(:grant)
      visit "/site/topics/preview/#{@topic.id}?version=1"
      body_should_contain 'Version 1'
    end
  end

  private

    def should_have_functioning_moderation_pages(item, controller_name, zoom_class_name, super_user = false)
      visit "/site/#{controller_name}/show/#{item.id}"

      body_should_contain "New #{controller_name.singularize} updated again"
      body_should_contain "History"

      visit "/site/#{controller_name}/history/#{item.id}"
      body_should_contain "Revision History: New #{controller_name.singularize} updated again"
      body_should_contain "Back to live"
      1.upto(3) do |i|
        body_should_contain "# #{i}"
      end

      1.upto(2) do |i|
        visit "/site/#{controller_name}/preview/#{item.id}?version=#{i}"
        body_should_contain "Preview revision ##{i}: view live"
        body_should_contain "#{zoom_class_humanize(zoom_class_name)}: #{item.versions.find_by_version(i).title}"
        body_should_contain item.versions.find_by_version(i).description
        body_should_contain "Actions"
        if super_user
          body_should_contain I18n.t('topics.preview_actions.make_live')
          body_should_contain I18n.t('topics.preview_actions.reject')
        end
      end
    end
end
