require 'spec_helper'

describe Comment do
  let(:comment) { Comment.new }

  it "does not blow up when you initialize it" do
    comment
  end

  it "can be saved to the database with minimal data filled in" do
    comment_attrs = {
      title: "Non judemental",
      #description: "are you really going to wear those shoes?",
      commentable_id: StillImage.last,
      commentable_type: "still_image",
      #parent_id: ,
      basket_id: 1,
    }
    comment = Comment.new(comment_attrs)

    expect(comment).to be_valid
    expect { comment.save! }.to_not raise_error
  end
end 
