FactoryGirl.define do
  factory :topic do
    sequence(:title) { |n| "Topic Title #{n}" }
    topic_type
    basket
  end
end
