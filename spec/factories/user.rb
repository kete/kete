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
  end
end
