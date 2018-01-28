require 'spec_helper'

module SearchResultsHelpers
  def first_result
    find('.generic-result-wrapper', match: :first)
  end

  def first_result_text
    first_result.find(".generic-result-header")
  end

  def first_image
    find('.image-result-wrapper', match: :first)
  end

  def first_image_text
    first_image.find(".image-result-header")
  end

  def top_pagination_links
    all(".pagination")[0]
  end

  def bottom_pagination_links
    all(".pagination")[1]
  end
end

feature "Browse search results" do
  include SearchResultsHelpers

  before do
    visit "/"
    within("#main-nav") do
      click_link('Browse')
    end
  end

  it "Searching works" do
    expect(page.status_code).to be(200)
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-header')).to have_text('Manakau School 125th Jubilee 2013 and Dedication Ceremony at the completion of the Jubilee')
  end

  it "Related items summary is displayed" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.generic-result-related')).to have_text('Related: 28 Topics and 3 Still images')
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 3)
  end

  it "Related items images load" do
    first_result = find('.generic-result-wrapper', match: :first)
    expect(first_result.find('.topic-result-related-images')).to have_css('img', count: 3)
  end

  it "Searching by type works" do
    expect(page).to have_content "Topics (2,203)"
    expect(first_result_text).to have_content "Manakau School 125th Jubilee 2013 and Dedication Ceremony at the completion of the Jubilee"

    click_on "Images (21,792)"
    expect(first_image_text).to have_content "Manakau School 125th Jubilee Rev Kahira Rau blessing the totem poles"

    click_on "Audio (106)"
    expect(first_result_text).to have_content "Paraparaumu, 1942 by Bernard Smith 22 April 2012"

    click_on "Video (92)"
    expect(first_result_text).to have_content "Behind the Hedges 2013 - Garden 5 Music for Lunch smaller file"

    click_on "Web links (244)"
    expect(first_result_text).to have_content "'Loveable rogue' as colourful as his forgeries"

    click_on "Documents (2,677)"
    expect(first_result_text).to have_content "Scrapbook 6 Page 42"
  end

  it "Top Pagination works" do
    top_pagination_links.click_on "Next »"
    expect(first_result_text).to have_content "Diary of Herbert (Bert) Denton"
    top_pagination_links.click_on "6"
    expect(first_result_text).to have_content "Dick Denton's Scrapbook No. 7"
    top_pagination_links.click_on "« Previous"
    expect(first_result_text).to have_content "Shannon School 1889-1900s"
  end

  it "Bottom Pagination works" do
    click_on "Images (21,792)"
    bottom_pagination_links.click_on "Next »"
    expect(first_image_text).to have_content "1 Jervois Terrace, Ohau"
    bottom_pagination_links.click_on "4"
    expect(first_image_text).to have_content "The World's Biggest Goldie"
    bottom_pagination_links.click_on "« Previous"
    expect(first_image_text).to have_content "Miss Clarke, Shannon, turns 90"
  end
end

feature "Search for a particular item" do
  include SearchResultsHelpers

  it "can search from the main page" do
    visit "/"
    within "#head-search-wrapper" do
      fill_in "search_terms", with: "Beach"
      click_button "Go"
    end

    expect(page).to have_content "Topics (162)"
    expect(first_result_text).to have_content "Houses of the Horowhenua 2011"

    click_on "Images (645)"
    expect(first_image_text).to have_content "Waikawa Beach Road to Waikawa Beach settlement, 1965"

    click_on "Audio (3)"
    expect(first_result_text).to have_content "Ash Bell The Country Boy 6 May 2012"

    click_on "Video (2)"
    expect(first_result_text).to have_content "32 lb Whitebait Shoal!"

    click_on "Web links (5)"
    expect(first_result_text).to have_content "Waitarere web site"

    click_on "Documents (193)"
    expect(first_result_text).to have_content "Reminiscences of an old colonist 1908"
  end

  it "Top Pagination of searched results works" do
    visit "/"
    within "#head-search-wrapper" do
      fill_in "search_terms", with: "Beach"
      click_button "Go"
    end

    top_pagination_links.click_on "Next »"
    expect(first_result_text).to have_content "Foxton 1888-1988 - Other Communications"
    top_pagination_links.click_on "6"
    expect(first_result_text).to have_content "Corrie Swanwick Funeral"
    top_pagination_links.click_on "« Previous"
    expect(first_result_text).to have_content "Foxton 1888-1988 - Community Service"
  end

  it "Bottom Pagination of searched results works" do
    visit "/"
    within "#head-search-wrapper" do
      fill_in "search_terms", with: "Beach"
      click_button "Go"
    end

    click_on "Images (645)"
    bottom_pagination_links.click_on "Next »"
    expect(first_image_text).to have_content "Waikawa Beach settlement and Waikawa River mouth, 1965"
    bottom_pagination_links.click_on "4"
    expect(first_image_text).to have_content "Otaki Beach township and Waitohu Stream mouth, 1965"
    bottom_pagination_links.click_on "« Previous"
    expect(first_image_text).to have_content "Waitarere Beach Belle winners, 1969"
  end
end
