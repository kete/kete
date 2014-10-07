FactoryGirl.define do
  factory :image_file do

    filename "furry.jpg"
    content_type "image/jpeg"
    size Random.rand(10000000)

    #parent_id: nil
    #thumbnail: nil
    # width Random.rand(10000000)
    # height Random.rand(10000000)

    trait :with_still_image do
      association :still_image, factory: :saveable_still_image
    end

  end
end
