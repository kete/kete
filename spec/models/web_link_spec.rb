require 'spec_helper'

describe WebLink do
  let(:web_link) { WebLink.new }

  it "does not blow up when you initialize it" do
    web_link
  end

  it "can be saved to the database with minimal data filled in" do
    web_link_attrs = {
       title: "Merube",  
          # NOTE:  title IS SAVED AS "blank title" for some reason
          #        but can be correctly set with wl.title = "Merube" 
          #        after it is saved.
       #description: "Wonderful ideas. Stunning. Gorgeous",
       url: "http://merube.com/",
       basket_id: 1,
    }

    web_link = WebLink.new(web_link_attrs)

    expect(web_link).to be_valid


    # web_link needs to have a basket before it will save
    # TODO: this implies that basket should be checked by a validation ???
    web_link.basket = basket

    expect { web_link.save! }.to_not raise_error
    
    expect(web_link.versions.size).to eq(1)
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
