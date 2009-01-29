# we use this to maintain unicode characters in unescaped form in our urls
module Utf8UrlFor
  unless included_modules.include? Utf8UrlFor
    # because of conflicts in controllers, we rely on url_for
    # being defined in the calling env
    # def self.included(klass)
    # klass.send :include, ActionController::UrlWriter
    # end
    # !!! use this sparingly
    # only where you absolutely can't have escaped unicode
    # like populating search records
    # or creating a search term to search against search records
    def utf8_url_for(options)
      # Make sure :id id an integer, and not the value of to_param (because changing
      # titles or private version seemed to lose related items because of this)
      options[:id] = options[:id].to_i # .to_i works on int/float/fixnum/string/or item object (via method that returns id)
      escaped_url = url_for(options)
      unescaped_url = CGI::unescape(escaped_url)
    end
  end
end

