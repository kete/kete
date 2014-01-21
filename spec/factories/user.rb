FactoryGirl.define do
  factory :user do
  end

  factory :savable_user, class: User do
    login 'quirk'
    email 'quirk@example.com'
    password 'quirk'
    password_confirmation 'quirk'
    agree_to_terms '1'
    security_code 'test'
    security_code_confirmation 'test'
    locale 'en' 
  end
end
