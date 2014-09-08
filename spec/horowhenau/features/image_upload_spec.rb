require 'spec_helper'

feature "Users can CRUD images" do

  def create_image
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")
    select 'Image', from: 'new_item_controller'
    fill_in 'still_image[title]', with: 'Some title'
    fill_in 'still_image[description]', with: 'Some description'
    attach_file('image_file[uploaded_data]', sample_image_path)
    click_button 'Create'
  end

  it "A user can upload a new image", js: true do
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

  it "A user can delete an existing image", js: true do
    create_image
    original_num_images = StillImage.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(StillImage.all.count).to eq(original_num_images - 1)
    expect(current_path).to match(/#{search_all_path}/)
  end
end
