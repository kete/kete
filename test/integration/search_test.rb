require File.dirname(__FILE__) + '/integration_test_helper'

class SearchTest < ActionController::IntegrationTest

  context "Topics with alphanumeric chars in title, description, and tags" do

    setup do
      add_jane_as_regular_user
      login_as('jane')
      @fields = { :title => 'abc', :description => 'def', :tag_list => 'ghi' }
      @should_have = Regexp.new("<h4><a (.+)>abc</a></h4>")
      @topic = new_topic(@fields)
    end

    should "be able to be found when searching topics" do
      make_search_at("/site/all/topics", @fields, @should_have)
    end

    should "be able to be found when searching contributors" do
      make_search_at("/site/all/topics/contributed_by/user/#{@jane.to_param}", @fields, @should_have)
    end

    should "be able to be found when searching taggings" do
      tag = Tag.last
      make_search_at("/site/all/topics/tagged/#{tag.id}", @fields, @should_have)
    end

  end

  context "Topics with utf8 chars in title, description, and tags" do

    setup do
      add_jane_as_regular_user
      login_as('jane')
      @fields = { :title => 'āēīōū', :description => 'こんにちは', :tag_list => 'مرحبا' }
      @should_have = Regexp.new("<h4><a (.+)>āēīōū</a></h4>")
      @topic = new_topic(@fields)
    end

    should "be able to be found when searching topics" do
      make_search_at("/site/all/topics", @fields, @should_have)
    end

    should "be able to be found when searching contributors" do
      make_search_at("/site/all/topics/contributed_by/user/#{@jane.to_param}", @fields, @should_have)
    end

    should "be able to be found when searching taggings" do
      tag = Tag.last
      make_search_at("/site/all/topics/tagged/#{tag.id}", @fields, @should_have)
    end

  end

  private

  def make_search_at(url, fields, should_have)
    visit url
    fields.each do |field,value|
      fill_in 'search_terms', :with => value
      click_button "Search"
      body_should_contain should_have, :number_of_times => 1
    end
  end

end