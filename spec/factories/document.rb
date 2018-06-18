# frozen_string_literal: true

FactoryGirl.define do
  factory :document do
    title 'The book of Nyan'
    filename 'nyan.pdf'
    content_type 'application/pdf'
    size 30
    basket
  end
end
