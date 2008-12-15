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
        @item = new_item(@@site_basket, "Topic")
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
      
      @image = on_new_image_form

      on_edit_image_form(@image) do
        fill_in 'still_image[title]', :with => "New image updated"
      end
      on_edit_image_form(@image) do
        fill_in 'still_image[title]', :with => "New image updated again"
      end
    end
    
    should "be able to visit item page" do
      visit "/site/images/show/#{@image.id}"
      body_should_contain "New image updated again"
      body_should_contain "History"
    end
    
    should "be able to visit history page for item" do
      visit "/site/images/history/#{@image.id}"
      body_should_contain "Revision History: New image updated again"
      body_should_contain "Back to live"
      1.upto(3) do |i|
        body_should_contain "# #{i}"
      end
    end
    
    should_eventually "be able to visit previews for each version of an item" do
      1.upto(2) do |i|
        visit "/site/images/preview/#{@image.id}?version=#{i}"
        body_should_contain "Preview revision ##{i}: view live"
        body_should_contain "Topic: #{@image.versions.find_by_version(i).title}"
        body_should_contain @image.versions.find_by_version(i).description
        body_should_contain "Actions"
        body_should_contain "Make this revision live"
        body_should_contain "reject"
      end
    end
    
  end
    
  private
  
    def on_new_image_form(options = {}, &block)
      visit "/site/baskets/choose_type"
      
      select "Image", :from => "new_item_controller"
      click_button "Choose"
      
      choose(options[:item_privacy]) if options[:item_privacy]
      fill_in "still_image[title]", :with => options[:title] || "New image"
      fill_in "still_image[tag_list]", :with => options[:tags] if options[:tags]
      
      file_path = options[:file_path] || File.join(RAILS_ROOT, "test/fixtures/files/white.jpg")
      content_type = options[:content_type] || "image/jpg"
      attach_file "image_file[uploaded_data]", file_path, content_type
      
      yield(block) if block_given?
      
      click_button "Create"
      
      body_should_contain "Image was successfully created."
      
      StillImage.last
    end
    
    def on_edit_image_form(image, &block)
      raise "Please pass a block with image form actions" unless block_given?
      
      visit "/#{image.basket.urlified_name}/images/edit/#{image.id}"
      body_should_contain "Editing Image"
      
      yield(block)
      
      click_button "Update"
      
      body_should_contain "Image was successfully updated."
    end

end