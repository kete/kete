require 'spec_helper'

feature "Users can upload video" do

  it "can store a new video file", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Video', from: 'new_item_controller'

    expect(page).to have_text("New Video")

    fill_in 'video[title]', with: 'Some title'
    fill_in 'video[description]', with: 'Some description'

    attach_file('video[uploaded_data]', video_file_path)
    click_button 'Create'

    expect(page).to have_text("Video was successfully created.")
  end
end



