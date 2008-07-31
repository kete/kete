# Kieran Pilkington, 2008/07/28
# We overwrite one of the Dispatch methods to give us the ability to make customized error pages
# for errors that occur before controllers are called (like when memcache is not online)
module ActionController
  class Dispatcher
    class << self

      def failsafe_response(fallback_output, status, originating_exception = nil)
        yield
      rescue Exception => exception
        begin
          log_failsafe_exception(status, originating_exception || exception)
          #failsafe_logger.info(exception)
          case exception.to_s
            when 'No connection to server' then
              body = failsafe_memcached_offline_body(status)
              body = body.gsub(/MEMCACHED_ERROR/, exception.to_s)
            else
              body = failsafe_response_body(status)
          end
          fallback_output.write body
          nil
        rescue Exception => failsafe_error # Logger or IO errors
          $stderr.puts "Error during failsafe response: #{failsafe_error}"
          $stderr.puts "(originally #{originating_exception})" if originating_exception
        end
      end

      private

        def failsafe_response_body(status)
          error_path = "#{error_file_path}/#{status.to_s[0...3]}.html"

          if File.exist?(error_path)
            File.read(error_path)
          else
            "<html>
            <body>
            <h1>#{status}</h1>
            </body>
            </html>"
          end
        end

        def failsafe_memcached_offline_body(status)
          error_path = "#{error_file_path}/memcached_offline.html"
          if File.exist?(error_path)
            File.read(error_path)
          else
            "<html>
            <body>
            <h1>#{status}</h1>
            <h2>Memcached Error</h2>
            <h3>MEMCACHED_ERROR</h3>
            </body>
            </html>"
          end
        end

    end
  end
end