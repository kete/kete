# frozen_string_literal: true

FactoryGirl.define do
  factory :video do
    title 'The Doge of Venice'
    filename 'doge.avi'
    content_type 'video/mp4'
    size 30
    basket
  end
end
