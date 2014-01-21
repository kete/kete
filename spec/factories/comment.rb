FactoryGirl.define do
  factory :validatable_comment, class: Comment do
    title "Non judemental"
    description "are you really going to wear those shoes?"
    commentable_id { create(:savable_video).id }
    commentable_type "still_image"
    #parent_id 

    factory :savable_comment do
      association :basket, factory: :savable_basket

      before(:create) do 
        # Required models:
        FactoryGirl.create(:savable_user) if User.count  == 0
      end  
    end
  end
end
