require 'spec_helper'

feature "Users can upload web links" do

  it "can store a new web link", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Web link', from: 'new_item_controller'

    expect(page).to have_text("New Web link")

    fill_in 'web_link[title]', with: 'Some web_link title'
    fill_in 'web_link[description]', with: 'Some web_link description'
    fill_in 'web_link[url]', with: 'http://weblink.example.com/'

    click_button 'Create'

    expect(page).to have_text("Web link was successfully created.")
  end
end




