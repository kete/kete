require 'spec_helper'

feature "Home Tag list" do
  it "All-tags link on homepage works" do
    visit "/"
    within("#tags-headline") do
      click_link('all')
    end
    expect(page.status_code).to be(200)
    expect(page).to have_text("Tags")

    click_on "Most Popular"
    expect(current_url).to end_with "/en/site/tags/list?direction=desc&order=number&page=1"

    click_on "Latest"
    expect(current_url).to end_with "/en/site/tags/list?direction=desc&order=latest&page=1"

    click_on "Random"
    expect(current_url).to end_with "/en/site/tags/list?direction=asc&order=random&page=1"

    click_on "By Name"
    expect(current_url).to end_with "/en/site/tags/list?direction=desc&order=alphabetical&page=1"

    click_link "wine making"
    expect(page).to have_content "Levin Amateur Winemakers and Brewers Club"
  end

  it "Specific tag links on homepage work" do
    visit "/"
    within("#tag-cloud") do
      first_tag_link = find('a', match: :first)
      first_tag_link.click
    end

    expect(current_url).to have_content "/en/site/search/tagged/?tag="
    expect(page).not_to have_content "Topics (0) Images (0) Audio (0) Video (0) Web links (0) Documents (0)"
  end
end

feature "Content-Item list" do
  it "viewing tagged items by type" do
    visit "/en/site/topics/2453-te-takere-begins-with-an-open-day-in-the-old-countdown-building"

    within "#tags_list" do
      expect(page).to have_css('a', count: 1)
      click_on("Te Takere")
    end

    expect(page).to have_content "Topics (6)"
    expect(page).to have_content "Te Takere"

    click_on "Images (37)"
    expect(page).to have_content "Replacing the roof gutter"

    click_on "Video (5)"
    expect(page).to have_content "Final blessing of rock in hole at Te Takere"

    click_on "Documents (3)"
    expect(page).to have_content "Stone man rescued"

    expect(page).to have_content "Audio (0)"
    expect(page).to have_content "Web links (0)"
  end
end
