require 'spec_helper'

describe Basket do
  it "does not blow up when you initialize it" do
    Basket.new
  end

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.build(:savable_basket) ).to be_a(Basket)
  end
end 
