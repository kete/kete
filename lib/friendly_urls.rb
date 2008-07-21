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
      skip_titles = [NO_PUBLIC_VERSION_TITLE, BLANK_TITLE]

      string = String.new

      if !self.attributes.include?('title')
        string = self.name
      else
        string = self.title
      end

      id_for_url = id.to_s
      id_for_url += format_friendly_for(string) unless skip_titles.include?(string)
      id_for_url
    end
  end
end
