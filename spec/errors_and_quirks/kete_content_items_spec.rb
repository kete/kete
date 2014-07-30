require 'spec_helper'

describe "Kete Cotent Items" do
  describe "quirks" do
    it "is valid without a basket, but cannot be saved without one" do
      content_item =  FactoryGirl.build(:validatable_document)
      expect(content_item).to be_valid
      expect { content_item.save! }.to raise_error

      FactoryGirl.create(:saveable_user)  # Required for save.
      content_item.basket =  FactoryGirl.create(:saveable_basket)
      expect { content_item.save! }.not_to raise_error
    end
  end
end
