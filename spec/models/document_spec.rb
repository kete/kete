require 'spec_helper'

describe Document do
  let(:document) { Document.new }

  it "does not blow up when you initialize it" do
    document
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_document) ).to be_valid
    expect { FactoryGirl.create(:validatable_document) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_document) ).to be_a(Document)
  end
end  
