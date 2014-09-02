require 'spec_helper'

feature "Comments (discussions)" do
  it "Clicking on a comment works as expected" do
    visit "/"
    click_on 'Browse'
    within('#content-tabs .nav-list') do
      click_on 'Discussions'
    end
    find_link('Re: David Clark', match: :first).click
    expect(page.status_code).to be(200)
    expect(page).to have_text 'Would you also be able to send me a copy of the information you have as well please?'
  end
end


