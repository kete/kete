# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/integration_test_helper'

::ActionController::UrlWriter.module_eval do
  default_url_options[:host] = SITE_NAME
end

class SearchTest < ActionController::IntegrationTest
  context "When getting results for topics, results" do
    setup do
      add_sally_as_regular_user
      login_as('sally')
      @topic = new_topic(:title => 'abcdef')
      @image_file_base_url = SystemSetting.full_site_url + '/image_files/'
      @first_image = new_still_image{ attach_file "image_file_uploaded_data", "white.jpg"}
    end

    should "have a topic with no related images should not have any images" do
      # check that browse has topic, but no images
      browse_for(@topic)
      body_should_not_contain Regexp.new("<img (.+)src=\"#{@image_file_base_url}.+\">")
    end

    context "after a related image has been added to the topic, the topic result" do
      setup do
        add_relation_between(@topic, 'StillImage', [@first_image.id])
      end

      should_eventually "show thumbnail for related image"
      # should "show thumbnail for related image" do
      #         browse_for(@topic)
      #         body_should_contain Regexp.new("<img (.+)src=\"#{SystemSetting.full_site_url}#{@first_image.thumbnail_file.public_filename}\">")
      #       end

      should "after the relationship with an image was unlinked should not have a thumbnail for image" do
        unlink_relation_between(@topic, 'StillImage', [@first_image.id])
        browse_for(@topic)
        body_should_not_contain Regexp.new("<img (.+)src=\"#{SystemSetting.full_site_url}#{@first_image.thumbnail_file.public_filename}\">")
      end
    end

    should_eventually "topic with more than 5 related images should only show first 5 image thumbnails"
    # should "topic with more than 5 related images should only show first 5 image thumbnails" do
    #       images = Array.new
    #       1.upto(6) do |i|
    #         images << new_still_image(:title => 'image ' + i.to_s) { attach_file "image_file_uploaded_data", "white.jpg"}
    #       end
    #       image_ids = images.collect { |image| image.id}
    #       add_relation_between(@topic, 'StillImage', image_ids)

    #       browse_for(@topic)
    #       images.each do |image|
    #         # index 5 is actually the six item, because we are dealing with array indexes, blah blah blah
    #         # so we don't want to see a match for the sixth image
    #         unless images.index(image) < 5
    #           body_should_not_contain Regexp.new("<img (.+)src=\"#{SystemSetting.full_site_url}#{image.thumbnail_file.public_filename}\">")
    #         else
    #           body_should_contain Regexp.new("<img (.+)src=\"#{SystemSetting.full_site_url}#{image.thumbnail_file.public_filename}\">")
    #         end
    #       end
    # end
  end

  ['jane', 'īōūāē', 'a&b'].each do |login|
    context "Topics with alphanumeric chars in title, description, and tags, using #{login} as a user login" do
      setup do
        @user = create_new_user({:login => login})
        @user.add_as_member_to_default_baskets
        @@users_created << @user
        login_as(login)
        @fields = { :title => 'abc', :description => 'def', :tag_list => 'ghi' }
        @should_have = Regexp.new("<h4><a (.+)>abc</a></h4>")
        @topic = new_topic(@fields)
      end

      should "be able to be found when searching topics" do
        make_search_at("/site/all/topics", @fields, @should_have)
      end

      should "be able to be found when searching contributors" do
        make_search_at("/site/all/topics/contributed_by/user/#{@user.to_param}", @fields, @should_have)
      end

      should "be able to be found when searching taggings" do
        tag = Tag.last
        make_search_at("/site/all/topics/tagged/#{tag.id}", @fields, @should_have)
      end
    end

    context "Topics with utf8 chars in title, description, and tags, using #{login} as a user login" do
      setup do
        @user = create_new_user({:login => login})
        @user.add_as_member_to_default_baskets
        @@users_created << @user
        login_as(login)
        @fields = { :title => 'āēīōū', :description => 'こんにちは', :tag_list => 'مرحبا' }
        @should_have = Regexp.new("<h4><a (.+)>āēīōū</a></h4>")
        @topic = new_topic(@fields)
      end

      should "be able to be found when searching topics" do
        make_search_at("/site/all/topics", @fields, @should_have)
      end

      should "be able to be found when searching contributors" do
        make_search_at("/site/all/topics/contributed_by/user/#{@user.to_param}", @fields, @should_have)
      end

      should "be able to be found when searching taggings" do
        tag = Tag.last
        make_search_at("/site/all/topics/tagged/#{tag.id}", @fields, @should_have)
      end
    end

    context "Topics with specials chars in title, description, and tags, using #{login} as a user login" do
      setup do
        @user = create_new_user({:login => login})
        @user.add_as_member_to_default_baskets
        @@users_created << @user
        login_as(login)
        @fields = { :title => 'One&Two', :description => 'Three<Four', :tag_list => 'Six>ive' }
        @should_have = Regexp.new("<h4><a (.+)>One&amp;Two</a></h4>")
        @topic = new_topic(@fields)
      end

      should "be able to be found when searching topics" do
        make_search_at("/site/all/topics", @fields, @should_have)
      end

      should "be able to be found when searching contributors" do
        make_search_at("/site/all/topics/contributed_by/user/#{@user.to_param}", @fields, @should_have)
      end

      should "be able to be found when searching taggings" do
        tag = Tag.last
        make_search_at("/site/all/topics/tagged/#{tag.id}", @fields, @should_have)
      end
    end
  end

  context "When a topic exists with related items, the search page" do
    setup do
      add_harry_as_regular_user
      login_as(:harry)

      @parent = new_topic
      @related_topic = new_topic(:relate_to => @parent)
      @related_image = new_still_image(:relate_to => @parent) { attach_file "image_file_uploaded_data", "white.jpg" }
    end

    should "show the related count on the search page" do
      visit "/#{@@site_basket.urlified_name}/all/topics/"
      body_should_contain 'Related: 1 Topic and 1 Image' # Parent item should have both
      body_should_contain 'Related: 1 Topic' # child topic should have parent
      visit "/#{@@site_basket.urlified_name}/all/images/"
      body_should_contain 'Related: 1 Topic' # child image should have parent
    end

    should "show the related counts on the search page after the parent is edited" do
      @parent = update_item(@parent)
      visit "/#{@@site_basket.urlified_name}/all/topics/"
      body_should_contain 'Related: 1 Topic and 1 Image' # Parent item should have both
      body_should_contain 'Related: 1 Topic' # child topic should have parent
      visit "/#{@@site_basket.urlified_name}/all/images/"
      body_should_contain 'Related: 1 Topic' # child image should have parent
    end
  end

  private

  def make_search_at(url, fields, should_have)
    visit url
    fields.each do |field,value|
      # test unquoted
      fill_in 'search_terms', :with => "#{value}"
      click_button "Search"
      body_should_contain should_have, :number_of_times => 1
      # test quoted
      fill_in 'search_terms', :with => "'#{value}'"
      click_button "Search"
      body_should_contain should_have, :number_of_times => 1
    end
  end

  def browse_for(item)
    visit '/site/all/' + zoom_class_controller(item.class.name)
    body_should_contain item.title
  end
end
