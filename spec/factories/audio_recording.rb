FactoryGirl.define do
  factory :validatable_audio_recording, class: AudioRecording do
    title "Ruby's Rock Steady"
    #description "Sweet and dandy. Straight out of Jamaica."
    filename "ruby_rr.wav"
    content_type "audio/mpeg"
    size 32
    #parent_id 

    factory :saveable_audio_recording do
      association :basket, factory: :saveable_basket

      after(:build) do 
        # Required models:
        FactoryGirl.create(:saveable_user)
      end  
    end
  end
end
