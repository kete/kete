module FriendlyUrls
  unless included_modules.include? FriendlyUrls
    def format_friendly_for(string)
      require 'unicode'
      Unicode::normalize_KD("-"+string+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
    end

    # make ids look like this for urls
    # /7-my-title-for-topic-7/
    # i.e. /id-title/
    # rails strips the non integers after the id
    # has to be in a model
    def format_for_friendly_urls
      "#{id}" + format_friendly_for(title)
    end
  end
end
