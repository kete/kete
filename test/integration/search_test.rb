require File.dirname(__FILE__) + '/integration_test_helper'

class SearchTest < ActionController::IntegrationTest

  context "When getting results for topics" do
    setup do
    end
    should_eventually "topic with 1 related image should show thumbnail for image"
    should_eventually "topic with more than 5 related images should only show first 5 image thumbnails"
    should_eventually "topic with no related images should not have any images"
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

end
