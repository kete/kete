require 'spec_helper'

feature "Comments (discussions)" do
  it "Clicking on a comment works as expected" do
    visit "/"
    click_on 'Browse'
    within('#content-tabs .nav-list') do
      click_on 'Discussions'
    end
    click_on 'Thanks Jo!'
    expect(page.status_code).to be(200)
    expect(page).to have_text 'and congratulations on your new appointment'
  end
end


