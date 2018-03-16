require 'spec_helper'

describe "Page footer Links" do
  it "displays the links" do
    visit "/"
    expect(page).to have_text 'Accessibility'
    expect(page).to have_text 'Sitemap'
  end

  it "Accessibility link works" do
    visit "/"
    click_on 'Accessibility'
    expect(page).to have_text 'Accessibility features of this website'
  end
  it "Site map link works" do
    visit "/"
    click_on 'Sitemap'
    expect(page).to have_text 'Chinese Remembered'
  end
end
