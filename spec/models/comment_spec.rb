require 'spec_helper'

describe Comment do
  let(:comment) { Comment.new }

  it "does not blow up when you initialize it" do
    comment
  end

  it "can be validated" do
    expect( FactoryGirl.build(:validatable_comment) ).to be_valid
    expect { FactoryGirl.create(:validatable_comment) }.to raise_error
  end 

  it "can be saved to the database with minimal data filled in" do
    expect( FactoryGirl.create(:saveable_comment) ).to be_a(Comment)
  end
end  
