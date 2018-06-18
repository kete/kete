# frozen_string_literal: true

FactoryGirl.define do
  factory :topic do
    # Tell FactoryGirl that `creator: ...` argument is *not* a model attribute
    # we want to set.
    transient do
      creator nil # set a default value for creator
    end

    sequence(:title) { |n| "Topic Title #{n}" }
    topic_type
    basket

    after(:create) do |topic, evaluator|
      # set the topic creator if one has been supplied. We have to do it like
      # this to get around a limitation in the Topic model.
      if evaluator.creator
        topic.creator = evaluator.creator
        topic.save!
      end
    end
  end
end
