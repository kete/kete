require 'spec_helper'

feature "Users can upload documents" do

  it "can store a new PDF file", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Document', from: 'new_item_controller'

    expect(page).to have_text("New Document")

    fill_in 'document[title]', with: 'Some title'

    attach_file('document[uploaded_data]', pdf_doc_file_path)

    click_button 'Create'

    expect(page).to have_text("Document was successfully created.")
  end

  it "can store a new MS Word document", js: true do
    sign_in
    click_on "Add Item"
    expect(page).to have_text("What would you like to add?")

    select 'Document', from: 'new_item_controller'

    expect(page).to have_text("New Document")

    fill_in 'document[title]', with: 'Some MS Word document'

    attach_file('document[uploaded_data]', ms_word_doc_file_path)

    click_button 'Create'

    expect(page).to have_text("Document was successfully created.")
  end
end



