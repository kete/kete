require 'spec_helper'

describe Document do
  let(:document) { Document.new }

  it "does not blow up when you initialize it" do
    document
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_document) ).to be_valid

    # ROB:  Not savable because of basket (see note in factory).
    expect { FactoryGirl.create(:validateable_document) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:savable_document) ).to be_a(Document)
  end
end  
