FactoryGirl.define do
  factory :topic_type do
    sequence(:name) { |n| "Topic Type #{n}" }
    description 'A description of a topic type'
  end
end
