# frozen_string_literal: true

require 'spec_helper'

feature 'A logged in user', js: true do
  let(:user) { FactoryGirl.create(:user, :activated, :with_default_baskets) }

  it 'can add a new Topic' do
    # given ...
    original_topic_count = Topic.count

    # when ...
    login(user)
    click_on 'Add Item'
    select 'Topic', from: 'new_item_controller'
    select 'Topic', from: 'topic[topic_type_id]'
    fill_in 'topic[title]', with: 'hello i am title'
    tinymce_fill_in 'topic_description', 'a description'
    fill_in 'topic[short_summary]', with: 'a short summary'
    fill_in 'topic[tag_list]', with: 'foo, bar'
    click_on 'Create'

    # then ...
    expect(page).to have_content('Topic was successfully created')
    expect(Topic.count).to eq(original_topic_count + 1)
  end
end
