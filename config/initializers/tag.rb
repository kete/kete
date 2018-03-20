# frozen_string_literal: true

# extending acts-as-taggable-on plugin's tag class
# so our tags look like this in URLs
# 1234-tag-name
module ActsAsTaggableOn
  Tag.class_eval do
    include FriendlyUrls
    def to_param
      format_for_friendly_urls
    end
  end
end
