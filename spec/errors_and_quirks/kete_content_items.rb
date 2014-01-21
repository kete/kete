require 'spec_helper'

describe "Kete Cotent Items" do
  describe "error:" do
    it "doesn't set title correctly on first save" do
      content_item = FactoryGirl.build(:saveable_still_image)
      content_item.title = "Not saved to DB"
      content_item.save
      expect(content_item.title).to eq("blank title")

      content_item.update_attribute(:title, "Saved to DB")
      expect(content_item.title).to eq("Saved to DB")
    end
  end

  describe "quirks" do
    it "is valid without a basket, but cannot be save without basket" do
      content_item =  FactoryGirl.build(:validatable_document)
      expect(content_item).to be_valid
      expect { content_item.save! }.to raise_error

      content_item.basket =  FactoryGirl.create(:saveable_basket)
      expect { content_item.save! }.not_to raise_error
    end
  end
end
