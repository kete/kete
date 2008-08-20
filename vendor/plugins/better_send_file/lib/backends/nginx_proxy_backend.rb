module Backends
  module NginxProxyBackend

    def send_file_via_proxy(path, options)
      logger.info "Streaming file #{path} using Nginx's X-Accel-Redirect" unless logger.nil?
      
      # Nginx doesn't want the full path to the file, just the path from the
      # site root onwards..
      path.gsub!(RAILS_ROOT, "")
      
      head "200 OK", 
        "X-Accel-Redirect" => "#{path}", 
        "Content-Disposition" => %(#{options[:disposition]}; filename=#{options[:filename]};),
        "Content-Type" => options[:type].strip
      
      # Prevent .html extension from being appended to the filename we suggested above.
      @performed_render = true
    end
    
  end
end