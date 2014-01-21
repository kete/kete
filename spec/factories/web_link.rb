FactoryGirl.define do
  factory :validatable_web_link, class: WebLink do
    title "Merube"  
       # NOTE:  title IS SAVED AS "blank title" for some reason
       #        but can be correctly set with wl.title = "Merube" 
       #        after it is saved.
    #description: "Wonderful ideas. Stunning. Gorgeous"
    url "http://merube.com/"

    factory :savable_web_link do
      association :basket, factory: :savable_basket

      before(:create) do 
        # Required models:
        FactoryGirl.create(:savable_user) if User.count  == 0
      end  
    end
  end
end
