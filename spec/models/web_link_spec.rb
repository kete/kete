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

  it "behaves like a Kete content item"

  describe "not stored attributes" do
    describe "#force_url" do
      it "is a flag that indicates ???" 
    end
  end

  describe "attributes" do
    describe "url" do
      it "must be present"
      it "must be unique but is not case sensitive"

      describe "validation of the end-point" do
        it "hits the URL with a HTTP HEAD request "
        it "validates the URL unless we ahve not been saved yet or force_url is set"
      end

    end
  end

  it "behaves like a private item"

  it "behaves liks a licenced resource"
  
  it "behaves like a versioned resource"
end
