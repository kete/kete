require 'spec_helper'

feature "Users can CRUD videos" do
  def create_video(attrs = nil)
    if attrs.nil?
      attrs = {
        title: 'some title',
        description: 'some desc',
      }
    end

    sign_in
    click_on "Add Item"
    select 'Video', from: 'new_item_controller'
    fill_in 'video[title]', with: attrs[:title]
    tinymce_fill_in 'video_description', attrs[:description]
    attach_file('video[uploaded_data]', video_file_path)
    click_button 'Create'
  end

  it "Create", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Video', from: 'new_item_controller'

    expect(page).to have_text("New Video")

    fill_in 'video[title]', with: 'Some title'
    tinymce_fill_in 'video_description', 'Some description'

    attach_file('video[uploaded_data]', video_file_path)
    click_button 'Create'

    expect(page).to have_text("Video was successfully created.")
  end

  it "Delete", js: true do
    create_video
    original_num_videos = Video.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(Video.all.count).to eq(original_num_videos - 1)
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
    create_video(old_attrs)

    click_on 'Edit'
    expect(page).to have_text('Editing Video')

    fill_in 'video[title]', with: new_attrs[:title]
    tinymce_fill_in 'video_description', new_attrs[:description]
    click_on 'Update'

    expect(page).to have_text('Video was successfully updated.')
    expect(page).to have_text(new_attrs[:title])
    expect(page).to have_text(new_attrs[:description])
  end
end



