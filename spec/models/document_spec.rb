require 'spec_helper'

describe Document do
  let(:document) { Document.new }

  it "does not blow up when you initialize it" do
    document
  end

  it "can be saved to the database with minimal data filled in" do
    document_attrs = {
      title: "The book of Nyan",
      #description: "nyan nyan nyan nyan nyan",
      filename: "nyan.pdf",
      content_type: "application/pdf",
      size: 30,
      #parent_id: ,
      basket_id: 1,
    }
    document = Document.new(document_attrs)

    expect(document).to be_valid
    expect { document.save! }.to_not raise_error
  end
end 
