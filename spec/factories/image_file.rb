FactoryGirl.define do
  factory :validatable_image_file, class: ImageFile do
    #parent_id: nil
    #thumbnail: nil
    filename "furry.JPG"
    content_type "image/jpeg"
    size Random.rand(10000000) 

    factory :saveable_image_file do
      width Random.rand(10000000)
      height Random.rand(10000000)
#      association :still_image, factory: :saveable_still_image
    end
  end
end
