FactoryGirl.define do
  factory :topic_type do
    sequence :name do |n| "Topic Type #{n}" end
    description "A description of a topic type"
  end
end 
