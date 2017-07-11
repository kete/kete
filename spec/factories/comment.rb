FactoryGirl.define do
  factory :comment do
    sequence(:title) { |n| "About #{n}" }
    sequence(:description) { |n| "This is a comment about #{n}" }
    basket

    commentable_id { create(:video).id }
    commentable_type 'still_image'
  end
end
