FactoryGirl.define do
  factory :validatable_comment, class: Comment do
    title "Non judemental"
    description "are you really going to wear those shoes?"

    factory :saveable_comment do
      commentable_id { create(:saveable_video).id }
      commentable_type "still_image"
      association :basket, factory: :saveable_basket
      #parent_id 

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user) if User.count == 0
      end  
    end
  end
end
