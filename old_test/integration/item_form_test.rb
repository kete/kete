# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class ItemFormTest < ActionController::IntegrationTest
  # test each item add/edit/delete forms

  context "The update functionality" do
    setup do
      add_july_as_regular_user
      login_as(:july)
    end

    context "when changing the topic type" do
      setup do
        @topic = new_topic
        visit "/#{@topic.basket.urlified_name}/topics/edit/#{@topic.id}"
        body_should_not_contain 'First Names'
        select /Person/, :from => 'topic_topic_type_id'
        click_button 'Update'
        body_should_contain "You've changed the topic type for this topic. Please review the available fields."
        fill_in 'topic_extended_content_values_first_names', :with => 'Joe'
        fill_in 'topic_extended_content_values_last_name', :with => 'Blogs'
        click_button 'Update'
        body_should_contain 'Topic was successfully updated.'
      end

      should "not break the history page for topics" do
        visit "/#{@topic.basket.urlified_name}/topics/history/#{@topic.id}" rescue nil
        body_should_not_contain 'It looks like there is no contributor'
        body_should_contain 'Revision History'
        body_should_contain 'Changed Topic Type from Topic to Person'
      end
    end
  end

  context "The delete functionality in production mode" do
    setup do
      enable_production_mode
      add_paul_as_super_user
      add_jane_as_super_user
      login_as(:paul)
      @topic = new_topic({ :title => 'Delete link test' })
    end

    teardown do
      disable_production_mode
    end

    should "work when different authorized people view it" do
      visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.id}"
      login_as(:jane)
      visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.id}"
      click_link 'Delete'
      body_should_contain 'Refine your results'
      visit "/#{@topic.basket.urlified_name}/topics/show/#{@topic.id}"
      body_should_contain '404 Error!'
    end
  end
end
