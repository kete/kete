FactoryGirl.define do
  factory :validatable_document, class: Document do
    title "The book of Nyan"
    #description "nyan nyan nyan nyan nyan"
    filename "nyan.pdf"
    content_type "application/pdf"
    size 30
    #parent_id 

    factory :savable_document do
      association :basket, factory: :savable_basket

      before(:create) do 
        # Required models:
        FactoryGirl.create(:savable_user) if User.count  == 0
      end  
    end
  end
end
