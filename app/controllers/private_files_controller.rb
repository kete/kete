class PrivateFilesController < ApplicationController
  
  class UnknownTypeError < StandardError
  end
  
  class PermissionDeniedError < StandardError
  end
  
  def show
    
    # Only respond to known types to avoid code injection attacks
    raise UnknownTypeError unless %w(documents image_files audio_recordings videos).member?(params[:type])
    
    id = (params[:a] + params[:b] + params[:c]).to_i
    @record = eval("#{params[:type].classify}").find(id)
    
    @current_basket = @record.basket

    if permitted_to_view_private_items?
      send_file   @record.full_filename, 
                  :type => @record.content_type, 
                  :length => @record.size,
                  :disposition => 'inline'
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
    session[:has_access_on_baskets] = current_user.get_basket_permissions if logged_in? || Hash.new
    render :text => "Error 401: Unauthorized", :status => 401
  end
  
end
