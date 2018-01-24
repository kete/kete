require 'spec_helper'

feature "Users can CRUD audio recordings" do
  def create_audio_recording(attrs = nil)
    if attrs.nil?
      attrs = {
        title: 'some title',
        description: 'some desc',
      }
    end

    sign_in
    click_on "Add Item"
    select 'Audio', from: 'new_item_controller'
    fill_in 'audio_recording[title]', with: attrs[:title]
    tinymce_fill_in 'audio_recording_description', attrs[:description]
    attach_file('audio_recording[uploaded_data]', audio_file_path)
    click_button 'Create'
  end

  it "Create", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Audio', from: 'new_item_controller'

    expect(page).to have_text("New Audio")

    fill_in 'audio_recording[title]', with: 'Some title'
    tinymce_fill_in 'audio_recording_description', 'Some description of stuff'

    attach_file('audio_recording[uploaded_data]', audio_file_path)
    click_button 'Create'

    expect(page).to have_text("Audio was successfully created.")
  end

  it "Delete", js: true do
    create_audio_recording
    original_num_audios = AudioRecording.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(AudioRecording.all.count).to eq(original_num_audios - 1)
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
    create_audio_recording(old_attrs)

    click_on 'Edit'
    expect(page).to have_text('Editing Audio')

    fill_in 'audio_recording[title]', with: new_attrs[:title]
    tinymce_fill_in 'audio_recording_description', new_attrs[:description]
    click_on 'Update'

    expect(page).to have_text('Audio was successfully updated.')
    expect(page).to have_text(new_attrs[:title])
    expect(page).to have_text(new_attrs[:description])
  end
end
