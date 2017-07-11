# This feature should accommodate these use cases (all accept status, but will default to 301):
# 
# * complete source url redirects to complete target url with status (e.g. old site urls mapped to new Kete version of content OR Kete item moved to a new basket)
# * partial source url (a pattern) redirects to complete target url (likely a set of old site urls under a unified stub mapped to single Kete location)
# * partial source url (a pattern) redirects to a partial target url (a pattern) (e.g. basket rename)
# 
# source_url_pattern should be on this host/domain (and probably not include host/domain part)
# but target_url_pattern can be on another host/domain
# i.e. we can register redirects to from our hosts to a new site (say we export a site's basket to another kete site)
# 
# you shouldn't register redirects with source_url_pattern or target_url_pattern that contains locales
# (e.g. use /basket_name/, not /en/basket_name/)
class RedirectRegistration < ActiveRecord::Base
  validates_presence_of :source_url_pattern, :target_url_pattern

  # match takes a request
  # and returns last (latest) redirect_registration that has a matching source_url_pattern
  # most complete match takes precedence
  scope :match, lambda { |request| 
    url = request.url.downcase
    # take out locale
    I18n.available_locales.each do |locale|
      re = Regexp.new("#{request.protocol}#{request.host}/#{locale}/")
      if url =~ re
        url = url.sub("/#{locale}/", "/")
        break
      end
    end

    without_host_url = url.sub(request.protocol, '').sub(request.host, '')
    without_file_and_query_string = without_host_url.sub(without_host_url.match(/[^\/]*$/)[0], '')

    { conditions: "LOWER(source_url_pattern) = \'#{url}\' OR
                      LOWER(source_url_pattern) = \'#{without_host_url}\' OR
                      LOWER(source_url_pattern) LIKE \'#{without_host_url}%\' OR
                      LOWER(source_url_pattern) LIKE \'#{without_file_and_query_string}%\'"
    }
  }

  def new_url(request_url)
    partial_re = Regexp.new(/^\/.+\/$/)

    if source_url_pattern =~ partial_re && target_url_pattern =~ partial_re
      new_url = request_url.sub(source_url_pattern, target_url_pattern)
    else
      # target_url_pattern is actually direct replacement
      new_url = target_url_pattern
    end
  end

end
