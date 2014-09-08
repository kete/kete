require 'spec_helper'

feature "Users can CRUD web links" do

  def create_web_link
    sign_in
    click_on "Add Item"
    select 'Web link', from: 'new_item_controller'
    fill_in 'web_link[title]', with: 'Some web_link title'
    fill_in 'web_link[description]', with: 'Some web_link description'
    fill_in 'web_link[url]', with: 'http://weblink.example.com/'
    click_button 'Create'
  end

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

  it "A user can delete an existing web link", js: true do
    create_web_link
    original_num_web_links = WebLink.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(WebLink.all.count).to eq(original_num_web_links - 1)
    expect(current_path).to match(/#{search_all_path}/)
  end
end




