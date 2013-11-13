require 'spec_helper'

describe WebLink do
  it "does not blow up when you initialize it" do
    foo = WebLink.new
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
