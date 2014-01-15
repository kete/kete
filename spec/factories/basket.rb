FactoryGirl.define do
  factory :basket do
    sequence :name do |n| "Basket name #{n}" end
  end
end 

