FactoryGirl.define do
  factory :audio_recording do
    title "Ruby's Rock Steady"
    filename 'ruby_rr.wav'
    content_type 'audio/mpeg'
    size 32
    basket
  end
end
