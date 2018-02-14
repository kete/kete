# frozen_string_literal: true

FactoryGirl.define do
  factory :image_file do
    # filename
    # content_type "image/jpeg"
    # size 4374 # hard-code to byte size of our fixture image
    uploaded_data { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'sample.jpg').to_s, 'image/jpeg') }
  end
end
