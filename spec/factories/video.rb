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
        FactoryGirl.create(:saveable_user) if User.count  == 0
      end

      factory :versionable_video do
        after(:build) do 
          # Required models:
          FactoryGirl.create(:video_content_type) if ContentType.where(class_name: "Video").empty?
          FactoryGirl.create(:user_content_type)  if ContentType.where(class_name: "User").empty?
        end
      end
    end
  end
end 


