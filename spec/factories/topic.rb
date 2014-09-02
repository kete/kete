FactoryGirl.define do
  factory :topic do
    sequence :title do |n| "Topic Title #{n}" end
    topic_type
    basket
  end
end 
