FactoryGirl.define do
  factory :content_type do
  end

  factory :savable_content_type, class: ContentType do
  end

  # must exist in the DB before you can create a video
  factory :video_content_type, class: ContentType do
    class_name "Video"
    description "foo"
    controller "video"
    humanized_plural "Videos"
    humanized "Video"
  end

  # must exist in the DB before you can create a user
  factory :user_content_type, class: ContentType do
    class_name "User"
    description "foo"
    controller "user"
    humanized_plural "Users"
    humanized "User"
  end

  # must exist in the DB before you can create a video
  factory :audio_recording_content_type, class: ContentType do
    class_name "AudioRecording"
    description "foo"
    controller "audio_recording"
    humanized_plural "Audio Recordings"
    humanized "Audio Recording"
  end



end 


