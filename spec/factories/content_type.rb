FactoryGirl.define do
  factory :validatable_content_type, class: ContentType do
    sequence(:class_name) {|n| "ContentItem#{n}" }
    sequence(:controller) {|n| "content_item_#{n}" }
    sequence(:humanized_plural) {|n| "Content Item #{n}s" }
    sequence(:humanized) {|n| "Content Item #{n}" }

    factory :saveable_content_type  do
      sequence(:description) {|n| "Content item #{n} content type" }
    end
  end


 singleton_content_types_needed_to_create_models = [
    [ :singleton_user_content_type,             "user" ],
    [ :singleton_audio_recording_content_type,  "audio_recording" ],
    [ :singleton_comment_content_type,          "comment" ], 
    [ :singleton_document_content_type,         "document" ], 
    [ :singleton_still_image_content_type,      "still_image" ], 
    [ :singleton_video_content_type,            "video" ], 
    [ :singleton_web_link_content_type,         "web_link" ]
  ]

 singleton_content_types_needed_to_create_models.each do |factory_symbol, name|
    factory factory_symbol, class: ContentType do
      class_name        name.classify                     # e.g. "Video"
      description       "#{name.humanize} content type"   # e.g. "Video content type"
      controller        name                              # e.g. "video"
      humanized_plural  name.humanize.pluralize           # e.g. "Videos"
      humanized         name.humanize                     # e.g. "Video"

      initialize_with { ContentType.find_or_create_by_controller(name) }
    end
  end
end 


