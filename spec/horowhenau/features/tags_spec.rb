require 'spec_helper'

feature "Tabs" do
  it "Link to all tags on homepage works" do
    visit "/"
    within("#tags-headline") do
      click_link('all')
    end
    expect(page.status_code).to be(200)
    expect(page).to have_text("Tags")
  end
end
