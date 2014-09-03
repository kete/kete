require 'spec_helper'

feature "Users can upload audio" do

  it "can store a new audio file", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Audio', from: 'new_item_controller'

    expect(page).to have_text("New Audio")

    fill_in 'audio_recording[title]', with: 'Some title'
    fill_in 'audio_recording[description]', with: 'Some description'

    attach_file('audio_recording[uploaded_data]', audio_file_path)
    click_button 'Create'

    expect(page).to have_text("stuff")
  end
end


