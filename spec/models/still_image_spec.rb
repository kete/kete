require 'spec_helper'

describe StillImage do
  let(:still_image) { StillImage.new }

  it "does not blow up when you initialize it" do
    still_image
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_still_image) ).to be_valid
    expect { FactoryGirl.create(:validatable_still_image) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_still_image) ).to be_a(StillImage)
  end
end


