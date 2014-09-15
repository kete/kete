require 'spec_helper'

feature "RSS Feeds" do
  scenario "RSS links in footer are disabled" do
    visit "/"
    expect(page).to_not have_css("#linkToRSS")
  end

  scenario "RSS links in <head> are disabled" do
    visit "/"
    expect(page).to_not have_css("link[type='application/rss+xml']", visible: false)
  end
end


