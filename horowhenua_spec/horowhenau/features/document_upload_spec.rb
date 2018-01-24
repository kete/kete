require 'spec_helper'

feature "Users can CRUD documents" do
  def create_document(doc_path, attrs = nil)
    if attrs.nil?
      attrs = {
        title: 'some title',
        url: 'http://www.foo.com'
      }
    end

    sign_in
    click_on "Add Item"
    select 'Document', from: 'new_item_controller'
    fill_in 'document[title]', with: attrs[:title]
    attach_file('document[uploaded_data]', doc_path)
    click_button 'Create'
  end

  it "Create PDF", js: true do
    create_document(pdf_doc_file_path)
    expect(page).to have_text("Document was successfully created.")
  end

  it "Create MS Word document", js: true do
    create_document(ms_word_doc_file_path)
    expect(page).to have_text("Document was successfully created.")
  end

  it "Delete", js: true do
    original_num_docs = Document.all.count
    create_document(pdf_doc_file_path)
    sleep 3
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(Document.all.count).to eq(original_num_docs)
    expect(current_path).to match(/#{basket_search_all_path('site')}/)
  end

  it "Edit", js: true do
    old_attrs = {
      title: 'some title',
    }
    new_attrs = {
      title: 'new title',
    }
    create_document(pdf_doc_file_path, old_attrs)

    click_on 'Edit'
    expect(page).to have_text('Editing Document')

    fill_in 'document[title]', with: new_attrs[:title]
    click_on 'Update'

    expect(page).to have_text('Document was successfully updated.')
    expect(page).to have_text(new_attrs[:title])
  end
end
