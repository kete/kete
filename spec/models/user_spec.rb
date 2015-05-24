require 'spec_helper'

describe User do
  it "does not blow up when you initialize it" do
    foo = User.new
  end

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.build(:user) ).to be_a(User)
  end
end

