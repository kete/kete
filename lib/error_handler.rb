# Kieran Pilkington, 2009/07/06
# Error handling middleware to give us the ability to make customized error pages
# for errors that occur before controllers are called (like when memcache is offline)
# Uses the example of vendor/rails/actionpack/lib/action_controller/failsafe.rb
module ActionController
  class Failsafe

    def call(env)
      @app.call(env)
    rescue Exception => exception
      # Reraise exception in test environment
      if defined?(Rails) && Rails.env.test?
        raise exception
      elsif exception.to_s.include?('MemCacheStore') && exception.to_s.include?('unable to find server')
        raise_custom_error(memcache_offline_response_body, exception.to_s)
      else
        failsafe_response(exception)
      end
    end

    private

    def raise_custom_error(body, error_message='')
      status, headers, body = 500, {'Content-Type' => 'text/html'}, body
      body.gsub!(/ERROR_MESSAGE/, CGI::escapeHTML(error_message))
      headers['Content-Length'] = body.length.to_s
      [status, headers, [body]]
    end

    def memcache_offline_response_body
      error_path = "#{self.class.error_file_path}/memcached_offline.html"
      if File.exist?(error_path)
        File.read(error_path)
      else
        "<html><body>
        <h1>500 Internal Server Error</h1>
        <h2>Memcached Offline</h2>
        <h3>ERROR_MESSAGE</h3>
        </body></html>"
      end
    end

  end
end