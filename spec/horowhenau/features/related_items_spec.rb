require 'spec_helper'

feature "Related Items" do

  it "are listed on a page" do
    visit "/en/site/topics/2453"

    within find("#related") do
      expect(page).to have_content "Related Items (11)"

      within find("#detail-linked-images") do
        sub_page = page
        expect(sub_page).to have_content "Images (6)"
        expect(sub_page).to have_css('ul img', count: 5)
        expect(sub_page).to have_content "1 more like this"
      end

      within find("#detail-linked-topics") do
        sub_page = page
        expect(sub_page).to have_content "Topics (2)"
        expect(sub_page).to have_content "Volunteers Demolition Team at Work"
        expect(sub_page).to have_css('ul a', count: 2)
      end

      within find("#detail-linked-video") do
        sub_page = page
        expect(sub_page).to have_content "Video (3)"
        expect(sub_page).to have_content "Salute to Fund Raisers"
        expect(sub_page).to have_css('ul a', count: 3)
      end      
    end
  end

  it "links to related items" do
    visit "/en/site/topics/2453"
    find("#detail-linked-images").click_on "Mayor Duffy takes a sledge hammer to the old Countdown building"
    expect(current_url).to  end_with "en/site/images/18040-mayor-duffy-takes-a-sledge-hammer-to-the-old-countdown-building"

    visit "/en/site/topics/2453"
    find("#detail-linked-topics").click_on "Volunteers Demolition Team at Work"
    expect(current_url).to  end_with "/en/site/topics/2477-volunteers-demolition-team-at-work"

    visit "/en/site/topics/2453"
    find("#detail-linked-video").click_on("Salute to Fund Raisers")
    expect(current_url).to end_with "/en/site/video/60-salute-to-fund-raisers"
  end

  it "links to searches for related items" do
    visit "/en/site/topics/2453"

    within find("#related") do
      link = find_link("Related Items (11)")[:href]
      expect(link).to end_with "/en/site/search/related_to?controller_name_for_zoom_class=Topic&related_item_id=2453&related_item_type=Topic&urlified_name=site"

      link = find("#detail-linked-images").find_link("Images")[:href]
      expect(link).to end_with "/en/site/search/related_to?controller_name_for_zoom_class=StillImage&related_item_id=2453&related_item_type=Topic&urlified_name=site"
      link = find("#detail-linked-images").find_link("1 more like this")[:href]
      expect(link).to end_with "/en/site/search/related_to?controller_name_for_zoom_class=StillImage&related_item_id=2453&related_item_type=Topic&urlified_name=site"

      link = find("#detail-linked-topics").find_link("Topics")[:href]
      expect(link).to end_with "/en/site/search/related_to?controller_name_for_zoom_class=Topic&related_item_id=2453&related_item_type=Topic&urlified_name=site"

      link = find("#detail-linked-video").find_link("Video")[:href]
      expect(link).to end_with "/en/site/search/related_to?controller_name_for_zoom_class=Video&related_item_id=2453&related_item_type=Topic&urlified_name=site"
    end
  end

  it "it searching by related items" do
    visit "/en/site/search/related_to?controller_name_for_zoom_class=Topic&related_item_id=2453&related_item_type=Topic&urlified_name=site"

    click_on "Images (6)"
    expect(page).to have_content "Mayor Duffy takes a sledge hammer to the old Countdown building" 

    click_on "Video (3)"
    expect(page).to have_content "Salute to Fund Raisers"

    click_on "Topics (2)"
    expect(page).to have_content "Volunteers Demolition Team at Work"
  end

  it "can be created between a topic and an image" do
    sign_in
    visit "/en/site/images/23115-manakau-school-125th-jubilee-rev-kahira-rau-blessing-the-totem-poles"
    within("#related_items") { click_on "Create" }

    expect(page).to have_content "What is the topic about?"
    select "General", from: "About a?"
    click_on "Choose Type"
    fill_in "topic[title]", with: 'testing relations'
    click_on 'Create'

    within("#related_items") do
      expect(page).to have_content("testing relations")
    end
  end

  it "can be created between a topic and a topic", js: true do
    old_overide_url = Rails.configuration.attachments_overide_url
    Rails.configuration.attachments_overide_url = 'http://horowhenua.kete.net.nz'

    sign_in
    visit "/en/site/topics/2725-shannon-school-1930-40"
    within("#related_items") { click_on "Create" }

    expect(page).to have_content("What would you like to add that relates to Shannon School 1930-40? Where would you like to add it?  ")
    select "Topic", from: 'Add a?'
    select "General", from: "About a?"
    fill_in "topic[title]", with: 'testing relations'
    click_on 'Create'

    within("#related_items") do
      expect(page).to have_content("testing relations")
    end

    Rails.configuration.attachments_overide_url = old_overide_url
  end
end
