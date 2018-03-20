# frozen_string_literal: true

FactoryGirl.define do
  factory :user do
    sequence(:login) { |n| "user_#{n}" }
    sequence(:email) { |n| "user_#{n}@example.com" }
    password 'quirk'
    password_confirmation 'quirk'
    agree_to_terms '1'
    security_code 'test'
    security_code_confirmation 'test'
    locale 'en'
    display_name 'John Doe'

    trait :activated do
      after(:create) do |u|
        u.activate
      end
    end

    trait :with_default_baskets do
      after(:create) do |u|
        u.add_as_member_to_default_baskets
      end
    end

    trait :with_site_admin_role do
      after(:create) do |u|
        u.roles << Role.where(name: 'site_admin').first
      end
    end
  end
end
