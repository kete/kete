FactoryGirl.define do
  factory :validatable_video, class: Video do
    title "The Doge of Venice"
    #description "Much trade. So wealth."
    filename "doge.avi"
    content_type "video/mp4"
    size 30
    #parent_id 

    factory :saveable_video do
      association :basket, factory: :saveable_basket

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user)
      end

      factory :versionable_video do
        after(:build) do 
          # Required models:
          FactoryGirl.create(:singleton_video_content_type)
          FactoryGirl.create(:singleton_user_content_type)
        end
      end
    end
  end
end 


