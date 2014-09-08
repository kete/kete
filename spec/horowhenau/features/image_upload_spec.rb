require 'spec_helper'

feature "Users can upload images" do

  it "A site admin can login", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Image', from: 'new_item_controller'

    expect(page).to have_text("New Image")

    fill_in 'still_image[title]', with: 'Some title'
    fill_in 'still_image[description]', with: 'Some description'

    attach_file('image_file[uploaded_data]', sample_image_path)
    click_button 'Create'

    expect(page).to have_text("Image was successfully created.")
  end
end
