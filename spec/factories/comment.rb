FactoryGirl.define do
  factory :comment do
    title "Non judemental"
    description "are you really going to wear those shoes?"
    commentable_id { create(:video).id }
    commentable_type "still_image"
    basket
  end
end
