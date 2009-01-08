module FriendlyUrls
  # by adding "-" or "_", we can change them to whatever demarkator makes sense in context
  CHARS_TO_REPLACE_IN_URLS = [' ', ',', '.', '`', ':', "\\", "\/", '&', '$', '<', '>', '=', '?', "'", "\"", "!", "\#", "-", "_"]

  unless included_modules.include? FriendlyUrls
    # eventually we will want to depreciate the use of normalize_KD transliteration
    # and just stick unicode in the URL
    # needs testing against IE6 to see if it works
    def format_friendly_for(string)
      require 'unicode'
      Unicode::normalize_KD("-"+string+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
    end

    def format_friendly_unicode_for(string, options = { })
      demarkator = options[:demarkator].nil? ? "-" : options[:demarkator]
      at_start = options[:at_start].nil? ? true : options[:at_start]
      at_end = options[:at_end].nil? ? false : options[:at_end]

      string = string.downcase

      CHARS_TO_REPLACE_IN_URLS.each { |char| string = string.gsub(char, demarkator) }

      if at_start
        string = demarkator + string
      else
        string.sub!(/^#{demarkator}+/, '')
      end

      if at_end
        string = string + demarkator
      else
        string = string.sub(/#{demarkator}+$/, '')
      end

      # get rid of multiple demarkators in a row
      string = string.gsub(/#{demarkator}+/, demarkator)
      string
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
      # eventually replace with unicode version
      # id_for_url += format_friendly_unicode_for(string) unless skip_titles.include?(string)
      id_for_url += format_friendly_for(string) unless skip_titles.include?(string)
      id_for_url
    end
  end
end
