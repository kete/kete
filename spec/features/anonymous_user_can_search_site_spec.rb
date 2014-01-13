require 'spec_helper'

describe "site search" do

  it "triggering site search from the homepage should not result in an error" do
    # given the required seeds exist
    load_production_seeds

    # ... when we visit the homepage
    visit '/'

    # ... and search for a string that does not exist in the DB
    within '#head-search-wrapper' do
      fill_in 'search_terms', with: 'something that does not exist'
      click_on 'Go'
    end

    # ... then the user should be presented with a message saying there were no results
    expect(page).to have_content 'No results of any type were found'
  end

  it "searches topic by exact title" do
 
    # Given a topic in the DB with a unique title ...
    unique = 'snowflake'
    FactoryGirl.create(:topic, title: unique)

    # ... which has been added to the search index ...
    PgSearch::Document.delete_all(searchable_type: "Topic") # reset search index
    PgSearch::Multisearch.rebuild(Topic) # add all Topics to it

    # ... when we visit the home page
    visit '/'

    # ... and search for exactly that title
    within '#head-search-wrapper' do
      fill_in 'search_terms', with: unique
      click_on 'Go'
    end

    # ... then the topic should appear as the sole search result
    expect(page).to have_content('Topics (1)')
    expect(page).to have_content(unique)
  end
end
