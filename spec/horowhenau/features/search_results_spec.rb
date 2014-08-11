require 'spec_helper'

def first_result
  find('.generic-result-wrapper', match: :first)
end

def first_result_text
  first_result.find(".generic-result-header")
end

feature "Browse search results" do

  before(:each) do
    visit "/"
    within("#main-nav") do
      click_link('Browse')
    end
  end

  it "Searching works" do
    expect(page.status_code).to be(200)
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-header')).to have_text('Levin Pottery Club')
  end

  it "Related items summary is displayed" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-related')).to have_text('Related: 4 Topics and 13 Still images')
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 5)
  end

  it "Related items images load" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 5)
  end

  it "Searching by type works" do
    expect(page).to have_content "Topics (2,203)"
    expect(first_result_text).to have_content "Levin Pottery Club"

    click_on "Images (21,792)"
    expect(first_result_text).to have_content "Shannon School 2010"

    click_on "Audio (106)"
    expect(first_result_text).to have_content "Horowhenua song"

    click_on "Video (92)"
    expect(first_result_text).to have_content "Daft Young Folk band perform"

    click_on "Web links (244)"
    expect(first_result_text).to have_content "Opiki Suspendion Bridge - web link"

    click_on "Documents (2,677)"
    expect(first_result_text).to have_content "Horowhenua County Council 100 years - Page 35"

    click_on "Discussions (386)"
    expect(first_result_text).to have_content "Thanks Jo!"
  end
end

feature "Search for a particular item" do
  it "can search from the main page" do
    visit "/"
    within "#head-search-wrapper" do
      fill_in "search_terms", with: "Beach"
      click_button "Go"
    end

    expect(page).to have_content "Topics (162)"
    expect(first_result_text).to have_content "Houses of the Horowhenua 2011"

    click_on "Images (645)"
    expect(first_result_text).to have_content "Waikawa Beach Road to Waikawa Beach settlement, 1965"

    click_on "Audio (3)"
    expect(first_result_text).to have_content "Ash Bell The Country Boy 6 May 2012"

    click_on "Video (2)"
    expect(first_result_text).to have_content "32 lb Whitebait Shoal!"

    click_on "Web links (5)"
    expect(first_result_text).to have_content "Waitarere web site"

    click_on "Documents (193)"
    expect(first_result_text).to have_content "Reminiscences of an old colonist 1908"

    click_on "Discussions (4)"
    expect(first_result_text).to have_content "Grandmother and Granddaughters on Beach"
  end
end