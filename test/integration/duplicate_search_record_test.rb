require File.dirname(__FILE__) + '/integration_test_helper'

# James - 2008-12-17
# This test is specifically geared to test for duplicate search record regression that has occured.

class DuplicateSearchRecordTest < ActionController::IntegrationTest
  context "A Kete instance" do
    
    setup do
      
      # Clean the zebra instance because we rely heavily on checking in this in tests.
      bootstrap_zebra_with_initial_records

      add_sarah_as_super_user
      login_as('sarah')
    end
    
    should "return no results because the zebra db is empty" do
      visit "/site/all/topics/"

      for name in ZOOM_CLASSES.map { |klass| zoom_class_plural_humanize(klass) }
      
        # Check that no records exist for each item type
        body_should_contain "#{name} (0)"
        
        # Check that no search results appear for each item type
        click_link "#{name} (0)"
        
        # Exception specifically for video
        name = "video" if name == "Videos"
        
        # Exception specifically for discussion
        name = "comments" if name == "Discussion"
        
        body_should_contain "Results in #{name.downcase}"
        body_should_contain "No results found."
        
      end
    end
    
    should "only show one search result for a new topic" do
      topic = new_topic :title => "This is a new topic"
      should_appear_once_in_search_results(topic)
    end
    
    should_eventually "only show one search result for a new item of any type"
    
    should "only show one search result for a new topic when a related topic is created" do
      create_a_topic_with_a_related_topic
    end
    
    should "only show one search result when a related topic is edited, then the original topic is edited" do
      create_a_topic_with_a_related_topic
      
      update_item(@related_topic, :title => "Related topic with title changed")
      [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
      
      update_item(@topic, :title => "Original topic with title changed")
      [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
    end
    
    should "only show one search result when a comment is added to a related topic" do
      [@@site_basket, new_basket].each do |basket|
        create_a_topic_with_a_related_topic(basket)
      
        update_item(@related_topic, :title => "Related topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
      
        update_item(@topic, :title => "Original topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
      
        visit "/#{basket.urlified_name}/topics/show/#{@related_topic.id}"
      
        click_link "join this discussion"
        fill_in "comment_title", :with => "This is a new comment!"
        fill_in "comment_description", :with => "Obviously this is a test."
        click_button "Save"
      
        body_should_contain "There are 1 comments in this discussion."
        body_should_contain Comment.last.title
        body_should_contain Comment.last.description, :number_of_times => 1
      
        update_item(@topic, :title => "Original topic with title changed")
        [@topic, @related_topic].each { |t| should_appear_once_in_search_results(t) }
      end
    end
    
    teardown do
      ZOOM_CLASSES.each do |class_name|
        eval(class_name).destroy_all
      end
    end
    
  end
  
  private
  
    def create_a_topic_with_a_related_topic(basket = @@site_basket)
      @topic = new_topic({ :title => "A topic" }, basket)
      should_appear_once_in_search_results(@topic)
      
      visit "/#{basket.urlified_name}/topics/show/#{@topic.id}/"
      
      # Emulate clicking the "Create" link for related topics
      @related_topic = new_item :new_path => "/#{basket.urlified_name}/topics/new?relate_to_topic=#{@topic.id}", :title => "A topic related to 'A topic'", :success_message => "Related topic was successfully created."
      
      body_should_contain "<a href=\"/#{basket.urlified_name}/topics/show/#{@related_topic.id}"
      should_appear_once_in_search_results(@topic)
    end
  
    def should_appear_once_in_search_results(item)
      visit "/#{item.basket.urlified_name}/all/#{zoom_class_controller(item.class.name)}/"
      
      basket_mention = item.basket == @@site_basket ? "" : item.basket.name + " "
      body_should_contain "Results in #{basket_mention}#{zoom_class_plural_humanize(item.class.name).downcase}"
      
      # We can't use the item title because it can appear several times legitimately.
      body_should_contain "item_#{item.id}_wrapper", :number_of_times => 1
    end
    
end