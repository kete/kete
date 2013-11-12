require 'spec_helper'

describe WebLink do
  it "smokes" do
    wl = WebLink.new
    # binding.pry
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

  it "behaves liks a licenced resource" do
    # this should not test the licenced item code, just that it has been included
    # a "licensed item" belongs to the Licenc model so should ahve a licence_id
    # wl = WebLink.new
    # expect(weblink).to respond_to(:license_id)
  end
  

  it "behaves like a versioned resource"

end
