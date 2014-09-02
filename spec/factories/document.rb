FactoryGirl.define do
  factory :validatable_document, class: Document do
    title "The book of Nyan"
    #description "nyan nyan nyan nyan nyan"
    filename "nyan.pdf"
    content_type "application/pdf"
    size 30
    #parent_id 

    factory :saveable_document do
      association :basket, factory: :saveable_basket

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user)
      end  
    end
  end
end
