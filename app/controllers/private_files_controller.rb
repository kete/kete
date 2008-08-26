class PrivateFilesController < ApplicationController
  
  class UnknownTypeError < StandardError
  end
  
  class PermissionDeniedError < StandardError
  end
  
  def show
    
    # Only respond to known types to avoid code injection attacks
    raise UnknownTypeError unless %w(documents image_files audio_recordings videos).member?(params[:type])
    
    # Instantiate an object instance based on the request parameters
    id = (params[:a] + params[:b] + params[:c]).to_i
    @record = eval("#{params[:type].classify}").find(id)
    
    @current_basket = @record.basket

    # Check we're allowed to view this file
    if permitted_to_view_private_items?
      
      send_file_options = {
        :type => @record.content_type, 
        :length => @record.size,
        :disposition => 'inline',
        :status => "200 OK"
      }
      
      # If we're using Nginx's send_file method, send the X-Accel-Redirect header.
      if SENDFILE_METHOD == "nginx"
        path = @record.full_filename.gsub(RAILS_ROOT, '')
        logger.info "Sending X-Accel-Redirect header #{path}" if logger
        head send_file_options[:status], "X-Accel-Redirect" => path, "Content-Type" => send_file_options[:type]
        
      else

        # Use Apache's X-SendFile if appropriate.
        if SENDFILE_METHOD == "apache"
          send_file_options.merge!(:x_sendfile => true)
        end

        # Use the normal send_file method if we're not working with Nginx.
        send_file(@record.full_filename, send_file_options)
      end
    else
      raise PermissionDeniedError
    end

  rescue ActiveRecord::RecordNotFound
    logger.warn("#{Time.now} - Requested File Not Found: #{params.inspect}")
    render :text => "Error 404: File Not Found", :status => 404
  rescue UnknownTypeError
    logger.warn("#{Time.now} - Unknown type requested: #{params.inspect}")
    render :text => "Error 400: Bad Request", :status => 400
  rescue PermissionDeniedError
    logger.warn("#{Time.now} - Permission Denied While Requesting Private Item: #{params.inspect}")
    session[:has_access_on_baskets] = logged_in? ? current_user.get_basket_permissions : Hash.new
    render :text => "Error 401: Unauthorized", :status => 401
  end
  
end
