require 'spec_helper'

describe WebLink do
  let(:web_link) { WebLink.new }

  it "does not blow up when you initialize it" do
    web_link
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_web_link) ).to be_valid
    expect { FactoryGirl.create(:validatable_web_link) }.to raise_error
  end

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_web_link) ).to be_a(WebLink)
  end

end
