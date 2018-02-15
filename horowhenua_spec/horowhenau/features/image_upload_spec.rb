require 'spec_helper'

describe "Users can CRUD images" do
  def create_image(attrs = nil)
    if attrs.nil?
      attrs = {
        title: 'some title',
        description: 'some desc',
        url: 'http://www.foo.com'
      }
    end

    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")
    select 'Image', from: 'new_item_controller'
    fill_in 'still_image[title]', with: attrs[:title]
    tinymce_fill_in 'still_image_description', attrs[:description]
    attach_file('image_file[uploaded_data]', sample_image_path)
    click_button 'Create'
  end

  it "Create", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Image', from: 'new_item_controller'

    expect(page).to have_text("New Image")

    fill_in 'still_image[title]', with: 'Some title'
    tinymce_fill_in 'still_image_description', 'Some description'

    attach_file('image_file[uploaded_data]', sample_image_path)
    click_button 'Create'

    expect(page).to have_text("Image was successfully created.")
  end

  it "Delete", js: true do
    create_image
    original_num_images = StillImage.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(StillImage.all.count).to eq(original_num_images - 1)
    expect(current_path).to match(/#{basket_search_all_path('site')}/)
  end

  it "Edit", js: true do
    old_attrs = {
      title: 'some title',
      description: 'some desc',
    }
    new_attrs = {
      title: 'new title',
      description: 'new desc',
    }
    create_image(old_attrs)

    click_on 'Edit'
    expect(page).to have_text('Editing Image')

    fill_in 'still_image[title]', with: new_attrs[:title]
    tinymce_fill_in 'still_image_description', new_attrs[:description]
    click_on 'Update'

    expect(page).to have_text('Image was successfully updated.')
    expect(page).to have_text(new_attrs[:title])
    expect(page).to have_text(new_attrs[:description])
  end
end
