# frozen_string_literal: true

FactoryGirl.define do
  factory :content_type do
    sequence(:class_name) { |n| "ContentItem#{n}" }
    sequence(:controller) { |n| "content_item_#{n}" }
    sequence(:humanized_plural) { |n| "Content Item #{n}s" }
    sequence(:humanized) { |n| "Content Item #{n}" }
    sequence(:description) { |n| "Content item #{n} content type" }
  end
end
