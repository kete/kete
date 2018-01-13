require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest
  context "If user portraits are disabled, there" do
    setup do
      configure_environment do
        set_constant :SystemSetting.enable_user_portraits?, false
      end

      add_lily_as_regular_user
      login_as('lily')
    end

    should "be no traces of portraits on any page" do
      visit "/site/account/show"
      body_should_not_contain 'id="portrait_help_div"'
      body_should_not_contain 'id="portraits"'
      body_should_not_contain 'id="profile_avatar"'
      body_should_not_contain 'id="selected_portrait"'
      body_should_not_contain 'id="portrait_help"'
      body_should_not_contain 'id="new_portrait"'
      @image = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      body_should_not_contain 'id="portrait-controls-box"'
      click_link 'History'
      body_should_not_contain 'class="user_contribution_link_avatar"'
      visit "/site/all/images/contributed_by/user/#{@lily.to_param}/"
      body_should_not_contain 'alt="lily\'s Avatar. "'
    end
  end

  context "If user portraits are enabled, a user" do
    setup do
      configure_environment do
        set_constant :SystemSetting.enable_user_portraits?, true
      end

      add_joe_as_regular_user
      login_as('joe')
    end

    should "not have selected portrait or other portraits if there are no portraits" do
      visit '/'
      click_link 'joe'
      body_should_not_contain "Selected<br />Portrait"
      body_should_not_contain "Other Portraits"
    end

    should "be able to access the portrait help box" do
      visit "/site/account/show"
      body_should_contain 'id="portrait_help_div"' # it'll be there, but hidden
      visit "/site/account/show?whats_this=true"
      body_should_contain 'id="portrait_help_div"'
    end

    context "in order to add portraits" do
      should "have a link available on the profile page to make a new default portrait" do
        visit "/site/account/show"
        click_link 'new portrait'
        body_should_contain 'New Image'
      end

      should "be able to add an image as default portrait automatically on item creation" do
        @item1 = new_still_image({ :selected_portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        portrait_are_in_order_for(@joe, [@item1])
        @item2 = new_still_image({ :selected_portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        portrait_are_in_order_for(@joe, [@item2, @item1])
      end

      should "be able to add an image as non default portrait automatically on item creation" do
        @item1 = new_still_image({ :portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        portrait_are_in_order_for(@joe, [@item1])
        @item2 = new_still_image({ :portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        portrait_are_in_order_for(@joe, [@item1, @item2])
      end
    end

    context "who has created an non portrait image" do
      setup do
        @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      should "be able to add existing image to portraits and have it show up as selected image" do
        item_base_url = "/en/site/images/show/#{@item.id}"
        visit item_base_url
        click_link 'Add image to portraits'
        body_should_contain "'#{@item.title}' has been added to your portraits."
        click_link 'joe'
        body_should_contain 'Selected<br />Portrait'
        body_should_contain Regexp.new("<a href=\"#{item_base_url}\"")
      end
    end

    context "with multiple portraits" do
      setup do
        @item1 = new_still_image({ :portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        @item2 = new_still_image({ :portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        @item3 = new_still_image({ :portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        @item4 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      should "have an Other Portraits section on profile and image show pages" do
        visit "/site/account/show"
        body_should_contain 'Other Portraits'
        [@item1, @item2, @item3].each do |item|
          visit "/site/images/show/#{item.to_param}"
          body_should_contain 'Other Portraits'
        end
      end

      should "not have an Other Portraits section on image show pages if the image is not a portrait" do
        visit "/site/images/show/#{@item4.to_param}"
        body_should_not_contain 'Other Portraits'
      end

      context "when controlling portraits with JS off" do
        should "be able to reorder, make selected, or remove portraits from the profile" do
          visit "/site/account/show"
          click_link "image_#{@item3.id}_controls_higher"
          portrait_are_in_order_for(@joe, [@item1, @item3, @item2])
          click_link "image_#{@item1.id}_controls_lower"
          portrait_are_in_order_for(@joe, [@item3, @item1, @item2])
          click_link "image_#{@item2.id}_controls_selected"
          portrait_are_in_order_for(@joe, [@item2, @item3, @item1])
          click_link "image_#{@item3.id}_controls_remove"
          portrait_are_in_order_for(@joe, [@item2, @item1])
        end

        should "be able to make selected or remove portraits from the image show page" do
          visit "/site/images/show/#{@item1.to_param}"
          click_link 'Remove image from portraits'
          portrait_are_in_order_for(@joe, [@item2, @item3])
          visit "/site/images/show/#{@item3.to_param}"
          click_link 'Make image selected portrait'
          portrait_are_in_order_for(@joe, [@item3, @item2])
        end
      end

      context "on the image show page" do
        should "exclude the displayed image and the default portrait" do
          [@item1, @item2, @item3].each do |item|
            visit "/site/images/show/#{item.to_param}"
            body_should_not_contain "id=\"image_#{item.id}\""
            body_should_not_contain "id=\"image_#{@item1.id}\""
          end
        end
      end
    end

    context "with a selected portrait" do
      setup do
        @item = new_still_image({ :selected_portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        add_paul_as_regular_user
        login_as('paul')
        @item2 = new_still_image({ :selected_portrait => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
        @item = update_item(@item)
      end

      should "have that image show up for item creators" do
        visit "/site/images/show/#{@item.to_param}"
        body_should_contain Regexp.new("<img(.+)#{@item.thumbnail_file.public_filename}(.+)>(.+)<a(.+)contributed_by/user/#{@joe.to_param}(.+)>#{@joe.user_name}</a>")
      end

      should "have that image show up for item editors" do
        visit "/site/images/show/#{@item.to_param}"
        body_should_contain Regexp.new("<img(.+)#{@item2.thumbnail_file.public_filename}(.+)>(.+)<a(.+)contributed_by/user/#{@paul.to_param}(.+)>#{@paul.user_name}</a>")
      end

      should "have that image show up for item history" do
        visit "/site/images/history/#{@item.to_param}"
        body_should_contain Regexp.new("<a(.+)contributed_by/user/#{@joe.to_param}(.+)><img(.+)#{@item.thumbnail_file.public_filename}(.+)>#{@joe.user_name}(.+)</a>")
      end

      should "have that image show up for user contributions" do
        visit "/site/all/images/contributed_by/user/#{@joe.to_param}"
        body_should_contain Regexp.new("<h3>(.+)<a(.+)site/account/show/#{@joe.to_param}(.+)>#{@joe.user_name}</a>(.+)<img(.+)#{@item.thumbnail_file.public_filename}(.+)></h3>")
      end

      context "and a comment on an item" do
        setup do
          add_sally_as_regular_user
          login_as('sally')
          @topic = new_topic
          login_as('joe')
          visit "/site/topics/show/#{@topic.to_param}"
          click_link 'join this discussion'
          fill_in 'comment_title', :with => 'Test Comment Title'
          fill_in 'comment_description', :with => 'Test Comment Description'
          click_button 'Save'
          body_should_contain 'Test Comment Title'
        end

        should "have that image show up for comments" do
          body_should_contain Regexp.new("<img(.+)#{@item.thumbnail_file.public_filename}(.+)>(.+)<a(.+)contributed_by/user/#{@joe.to_param}(.+)>#{@joe.user_name}</a>")
        end
      end
    end
  end

  private

  def portrait_are_in_order_for(user, order)
    assert order, user.user_portrait_relations.collect { |relation| relation.still_image_id }
  end
end
