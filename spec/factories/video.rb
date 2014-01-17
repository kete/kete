FactoryGirl.define do

  factory :validateable_video, class: Video do
    title "The Doge of Venice"
    #description "Much trade. So wealth."
    filename "doge.avi"
    content_type "video/mp4"
    size 30
    #parent_id 

    factory :saveable_video, class: Video do
      # ROB:  video needs to have a basket before it will save.
      #       This implies that basket should be checked by a validation.
      association :basket, factory: :saveable_basket

      before(:create) do 
        # Make sure required models exist in the database.
        FactoryGirl.create(:video_content_type) if ContentType.where(class_name: "Video").empty?
        FactoryGirl.create(:user_content_type)  if ContentType.where(class_name: "User").empty?
        FactoryGirl.create(:saveable_user)      if User.count  == 0
        end
    end
  end
end 


