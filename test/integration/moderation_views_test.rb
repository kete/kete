require File.dirname(__FILE__) + '/integration_test_helper'

class ModerationViewsTest < ActionController::IntegrationTest

  context "A Kete instance" do

    setup do

      # Ensure a user account to log in with is present
      add_grant_as_super_user
      login_as('grant')
    end
    
    context "Topic with multiple versions" do
      
      setup do
        
        # Create a test item
        @item = new_topic
        update_item(@item)
        update_item(@item, :title => "Homepage Title Updated Again")
      end
      
      should "be able to visit item page" do
        visit "/site/topics/show/#{@item.id}"
        body_should_contain "Topic: Homepage Title Updated Again"
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
          body_should_contain "Make this revision live"
          body_should_contain "reject"
        end
      end
      
    end
    
  end
  
  context "Image with multiple versions" do
    
    setup do
      
      # Ensure a user account to log in with is present
      add_grant_as_super_user
      login_as('grant')
      
      @image = new_image do
        attach_file "image_file[uploaded_data]", \
          File.join(RAILS_ROOT, "test/fixtures/files/white.jpg"), "image/jpg"
      end
  
      update_image(@image, :title => "New image updated")
      update_image(@image, :title => "New image updated again")
    end
    
    should "have functioning moderation pages" do
      should_have_functioning_moderation_pages(@image, 'images', 'Image')
    end
    
  end
    
  private
  
    def should_have_functioning_moderation_pages(item, controller_name, zoom_class_name)
    
      visit "/site/#{controller_name}/show/#{item.id}"
      body_should_contain "New #{controller_name} updated again"
      body_should_contain "History"

      visit "/site/#{controller_name}/history/#{item.id}"
      body_should_contain "Revision History: New #{controller_name} updated again"
      body_should_contain "Back to live"
      1.upto(3) do |i|
        body_should_contain "# #{i}"
      end

      1.upto(2) do |i|
        visit "/site/#{controller_name}/preview/#{item.id}?version=#{i}"
        body_should_contain "Preview revision ##{i}: view live"
        body_should_contain "#{zoom_class_name}: #{item.versions.find_by_version(i).title}"
        body_should_contain item.versions.find_by_version(i).description
        body_should_contain "Actions"
        body_should_contain "Make this revision live"
        body_should_contain "reject"
      end
      
    end

end