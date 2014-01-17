require 'spec_helper'

describe ContentType do
  it "does not blow up when you initialize it" do
    ContentType.new
  end

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.build(:saveable_content_type) ).to be_a(ContentType)
  end
end 
