require 'net/http'
require 'uri'
require 'socket'

module ActiveRecord
 module Validations
   module ClassMethods

     # Validates a URL.
     def validates_http_url(*attr_names)
       configuration = {
        :message_not_accessible => "is not accessible when we tried the link",
        :message_wrong_content => "is not of the appropriate content type",
        :message_moved_permanently => "has moved permanently",
        :message_url_format => "is not formatted correctly. (Missing 'http://'?)"
       }
       configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
       validates_each(attr_names, configuration) do |record, attr_name, value|

         # Ignore blank URLs, these can be validated with validates_presence_of
         if value.nil? or value.empty?
           next
         end

         begin
           moved_retry ||= false
           not_allowed_retry ||= false
           # Check Formatting
           raise if not value =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
           response = nil
           url = URI.parse(value)
           url.path = "/" if url.path.length < 1
           http = Net::HTTP.new(url.host, (url.scheme == 'https') ? 443 : 80)
           if url.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
           end
           headers = Object.const_defined?('SITE_URL') ? { "User-Agent" => "#{SITE_URL} link checking mechanism via Ruby Net/HTTP" } : { "User-Agent" => "Ruby Net/HTTp used for link checking mechanism" }
           response = not_allowed_retry ? http.request_get(url.path, headers) {|r|} : http.request_head(url.path, headers)
           # response = not_allowed_retry ? http.request_get(url.path) {|r|} : http.request_head(url.path)
           # Comment out as you need to
           allowed_codes = [
            Net::HTTPMovedPermanently,
            Net::HTTPOK,
            Net::HTTPCreated,
            Net::HTTPAccepted,
            Net::HTTPNonAuthoritativeInformation,
            Net::HTTPPartialContent,
            Net::HTTPFound,
            Net::HTTPTemporaryRedirect,
            Net::HTTPSeeOther
           ]
           # If response is not allowed, raise an error
           raise unless allowed_codes.include?(response.class)
           # Check if the model requires a specific content type
           unless configuration[:content_type].nil?
             record.errors.add(attr_name, configuration[:message_wrong_content]) if response['content-type'].index(configuration[:content_type]).nil?
           end
         rescue
          # Has the page moved?
          if response.is_a?(Net::HTTPMovedPermanently)
           unless moved_retry
            moved_retry = true
            value += "/" # In case webserver is just adding a /
            retry
           else
            record.errors.add(attr_name, configuration[:message_moved_permanently])
           end
          elsif response.is_a?(Net::HTTPMethodNotAllowed) || response.is_a?(Net::HTTPInternalServerError)
           unless not_allowed_retry
            # Retry with a GET
            not_allowed_retry = true
            retry
           else
             if response.is_a?(Net::HTTPInternalServerError)
               record.errors.add(attr_name, configuration[:message_not_accessible]+". The site link in question has had a problem. Please raise the issue with them and let them know that requests to the link break when coming from the automatic link checking mechanism on this site.")
             else
               record.errors.add(attr_name, configuration[:message_not_accessible]+" (GET method not allowed)")
             end
           end
          else
            # if response is nil, then it's a format issue
            if response.nil?
              record.errors.add(attr_name, configuration[:message_url_format])
            else
              # Just Plain non-accessible
              record.errors.add(attr_name, configuration[:message_not_accessible]+". This is what the website in question returned to us: "+response.class.to_s)
            end
          end
         end
       end
     end

     def validates_http_domain(*attr_names)
      validates_each(attr_names) do |record, attr_name, value|
       # Set valid true on successful connect (all we need is one, one is all we need)
        failed = true
          possibilities = [value, "www."+value]
          possibilities.each do |url|
          begin
            temp = Socket.gethostbyname(url)
          rescue SocketError
            next
          end
            failed = false
            break
          end
        record.errors.add(attr_name, "cannot be resolved.") if failed
      end
    end
   end
 end
end
