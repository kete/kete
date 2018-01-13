require 'spec_helper'

feature 'Users can CRUD web links' do
  def create_web_link(attrs = nil)
    attrs = {
      title: 'some title',
      description: 'some desc',
      url: 'http://www.foo.com'
    } if attrs.nil?

    sign_in
    click_on 'Add Item'
    select 'Web link', from: 'new_item_controller'
    fill_in 'web_link[title]', with: attrs[:title]
    tinymce_fill_in('web_link_description', attrs[:description])
    fill_in 'web_link[url]', with: attrs[:url]
    click_button 'Create'
  end

  it 'Create', js: true do
    sign_in
    click_on 'Add Item'
    expect(page).to have_text('What would you like to add?')

    select 'Web link', from: 'new_item_controller'

    expect(page).to have_text('New Web link')

    fill_in 'web_link[title]', with: 'Some web_link title'
    tinymce_fill_in 'web_link_description', 'Some web_link description'
    fill_in 'web_link[url]', with: 'http://weblink.example.com/'

    click_button 'Create'

    expect(page).to have_text('Web link was successfully created.')
  end

  it 'Delete', js: true do
    create_web_link
    original_num_web_links = WebLink.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(WebLink.all.count).to eq(original_num_web_links - 1)
    expect(current_path).to match(/#{basket_search_all_path('site')}/)
  end

  it 'Edit', js: true do
    old_attrs = {
      title: 'some title',
      description: 'some desc',
      url: 'http://www.foo.com'
    }
    new_attrs = {
      title: 'new title',
      description: 'new desc'
    }
    create_web_link(old_attrs)

    click_on 'Edit'
    expect(page).to have_text('Editing Web link')

    fill_in 'web_link[title]', with: new_attrs[:title]
    tinymce_fill_in 'web_link_description', new_attrs[:description]
    click_on 'Update'

    expect(page).to have_text('Web link was successfully updated.')
    expect(page).to have_text(new_attrs[:title])
    expect(page).to have_text(new_attrs[:description])
  end
end
