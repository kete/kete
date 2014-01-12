require 'spec_helper'

describe "production seeds" do
  it "production seeds should load correctly" do
    load_production_seeds
    expect(User.count).to eq(2)
    expect(Basket.count).to eq(4)
    expect(Topic.count).to eq(15)
    expect(TopicType.count).to eq(5)
  end
end 
