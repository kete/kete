require 'spec_helper'

describe ContentType do
  it "does not blow up when you initialize it" do
    ContentType.new
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_content_type) ).to be_valid
    expect { FactoryGirl.create(:validatable_content_type) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_content_type) ).to be_a(ContentType)
  end
end 
