FactoryGirl.define do
  factory :validatable_web_link, class: WebLink do
    title "Merube"  
       # NOTE:  title IS SAVED AS "blank title" for some reason
       #        but can be correctly set with wl.title = "Merube" 
       #        after it is saved.
    #description: "Wonderful ideas. Stunning. Gorgeous"
    url "http://merube.com/"

    factory :saveable_web_link do
      association :basket, factory: :saveable_basket

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user)
      end  
    end
  end
end
