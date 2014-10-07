FactoryGirl.define do
  factory :validatable_still_image, class: StillImage do
    title "Fur Seal"
    #description "Has a cap and a chain."

    factory :saveable_still_image do
      association :basket, factory: :saveable_basket

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user) if User.count  == 0
      end
    end
  end
end
