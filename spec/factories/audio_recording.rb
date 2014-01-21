FactoryGirl.define do
  factory :validatable_audio_recording, class: AudioRecording do
    title "Ruby's Rock Steady"
    #description "Sweet and dandy. Straight out of Jamaica."
    filename "ruby_rr.wav"
    content_type "audio/mpeg"
    size 32
    #parent_id 

    factory :savable_audio_recording do
      association :basket, factory: :savable_basket

      before(:create) do 
        # Required models:
        FactoryGirl.create(:savable_user) if User.count  == 0
      end  
    end
  end
end
