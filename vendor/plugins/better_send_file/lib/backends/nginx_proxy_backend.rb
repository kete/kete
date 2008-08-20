module Backends
  module NginxProxyBackend

    def send_file_via_proxy(path, options)
      logger.info "Streaming file #{path} using Nginx's X-Accel-Redirect" unless logger.nil?
      
      headers["Cache-Control"] = "private"
      headers["Content-Disposition"] = %(#{options[:disposition]}; filename=#{options[:filename]};)
      headers["Content-Type"] = options[:type].strip
      headers["X-Accel-Redirect"] = "#{path}"
      
      # Prevent .html extension from being appended to the filename we suggested above.
      @performed_render = true
    end
    
  end
end