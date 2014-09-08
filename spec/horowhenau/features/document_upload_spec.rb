require 'spec_helper'

feature "Users can upload documents" do

  def create_document(doc_path)
    sign_in
    click_on "Add Item"
    select 'Document', from: 'new_item_controller'
    fill_in 'document[title]', with: 'Some MS Word document'
    attach_file('document[uploaded_data]', doc_path)
    click_button 'Create'
  end

  it "can store a new PDF file", js: true do
    create_document(pdf_doc_file_path)
    expect(page).to have_text("Document was successfully created.")
  end

  it "can store a new MS Word document", js: true do
    create_document(ms_word_doc_file_path)
    expect(page).to have_text("Document was successfully created.")
  end

  it "A user can delete an existing document", js: true do
    create_document(pdf_doc_file_path)
    original_num_docs = Document.all.count
    click_on 'Delete' # poltergeist ignores confirm/alert modals by default
    expect(Document.all.count).to eq(original_num_docs - 1)
    expect(current_path).to match(/#{search_all_path}/)
  end
end



