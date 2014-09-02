require 'spec_helper'

describe ImageFile do
  let(:image_file) { ImageFile.new }

  it "does not blow up when you initialize it" do
    image_file
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_image_file) ).to be_valid
    expect { FactoryGirl.create(:validatable_image_file) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_image_file) ).to be_a(ImageFile)
  end
end 

