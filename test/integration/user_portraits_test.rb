require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest
  context "If user portraits are enabled, a user" do
    setup do
      configure_environment do
        set_constant :ENABLE_USER_PORTRAITS, true
      end

      add_joe_as_regular_user
      login_as('joe')
    end

    should "not have selected portrait or other portraits if there are no portraits" do
      visit '/'
      click_link 'joe'
      body_should_not_contain "selected portrait"
      body_should_not_contain "Other Portraits"
    end

    context "who has created one image" do
      setup do
        @item = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      should "be able to add existing image to portraits and have it show up as selected image" do
        item_base_url = "/site/images/show/#{@item.id}"
        visit item_base_url
        click_link 'Add image to portraits'
        body_should_contain "'#{@item.title}' has been added to your portraits"
        click_link 'joe'
        body_should_contain 'Selected<br />Portrait'
        body_should_contain Regexp.new("<a href=\"#{item_base_url}\"")
      end

      context "and that image has been made a portrait" do
        setup do
          UserPortraitRelation.new_portrait_for(@user, @item)
        end

        should "have the selected image by their resolved display name in on an item they created" do
          @created_item = new_topic
          visit "/site/topics/show/#{@created_item.id}"
          thumbnail_url = @item.public_filename
          created_by_string = "contributed_by/user/#{@user.to_param}/\"><img alt=\"#{@item.title}. \" src=\"#{thumbnail_url}\">, creator username, created by string "
          body_should_contain Regexp.new("contributed_by/user/#{@user.to_param}/><img.+ src=#{thumbnail_url}.+>")
        end
      end
    end

    # TODO:
    # test that shows that more than one portraits has "Other Portraits" on both image detail page and user account
    # tests that handle non-javascript reordering
    # ...
  end

end
