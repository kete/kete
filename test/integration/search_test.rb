require File.dirname(__FILE__) + '/integration_test_helper'

class SearchTest < ActionController::IntegrationTest

  context "Topics with alphanumeric chars in title, description, and tags" do

    setup do
      add_jane_as_regular_user
      login_as('jane')
      @topic = new_topic({ :title => 'abc', :description => 'def', :tag_list => 'ghi' })
    end

    should "be able to be found when searching" do
      visit "/site/all/topics"
      { :title => 'abc', :description => 'def', :tags => 'ghi' }.each do |field,value|
        fill_in 'search_terms', :with => value
        click_button "Search"
        body_should_contain Regexp.new("<h4><a (.+)>abc</a></h4>"), :number_of_times => 1
      end
    end

  end

  context "Topics with utf8 chars in title, description, and tags" do

    setup do
      add_jane_as_regular_user
      login_as('jane')
      @topic = new_topic({ :title => 'āūāōā', :description => 'こんにちは', :tag_list => 'مرحبا' })
    end

    should "be able to be found when searching" do
      visit "/site/all/topics"
      { :title => 'āūāōā', :description => 'こんにちは', :tags => 'مرحبا' }.each do |field,value|
        fill_in 'search_terms', :with => value
        click_button "Search"
        body_should_contain Regexp.new("<h4><a (.+)>āūāōā</a></h4>"), :number_of_times => 1
      end
    end

  end

end