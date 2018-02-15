class PrivateFilesController < ApplicationController
  class UnknownTypeError < StandardError
  end

  class PermissionDeniedError < StandardError
  end

  def show
    # Only respond to known types to avoid code injection attacks
    raise UnknownTypeError unless %w[documents image_files audio video].member?(params[:type])

    # Ensure we load the correct object type
    type = params[:type] == 'audio' ? 'audio_recordings' : params[:type]

    # Instantiate an object instance based on the request parameters
    id = (params[:a] + params[:b] + params[:c]).to_i
    @record = eval(type.classify.to_s).find(id)

    # images are a special case. We have to fetch
    # the still image from the image file to check
    # whether the current user can view the files
    @item = @record.is_a?(ImageFile) ? @record.still_image : @record

    @current_basket = @record.basket

    # Check we're allowed to view this file
    if current_user_can_see_private_files_for?(@item)

      send_file_options = {
        type: @record.content_type,
        length: @record.size,
        disposition: 'inline',
        status: '200 OK'
      }

      # If we're using Nginx's send_file method, send the X-Accel-Redirect header.
      if SENDFILE_METHOD == 'nginx'
        path = @record.full_filename.gsub(Rails.root, '')
        logger.info "Sending X-Accel-Redirect header #{path}" if logger
        head send_file_options[:status], 'X-Accel-Redirect' => path, 'Content-Type' => send_file_options[:type]

      else

        # Use Apache's X-SendFile if appropriate.
        if SENDFILE_METHOD == 'apache'
          send_file_options[:x_sendfile] = true
        end

        # Use the normal send_file method if we're not working with Nginx.
        send_file(@record.full_filename, send_file_options)
      end
    elsif params[:show_placeholder]
      # in the case of search results, we can't check if they are viewable
      # by the user because we don't have the item objects, so instead, when
      # the image gets requested, append show_placeholder to the URL, so if
      # the image is not authorized, we dont get a broken image because we
      # return one here
      no_public_version = File.join(Rails.root, 'public', 'images', 'no_public_version.gif')
      send_file_options = {
        type: 'image/gif',
        length: File.size(no_public_version),
        disposition: 'inline',
        status: '200 OK'
      }
      send_file(no_public_version, send_file_options)
    else
      raise PermissionDeniedError
    end
  rescue ActiveRecord::RecordNotFound
    logger.warn("#{Time.now} - Requested File Not Found: #{params.inspect}")
    render text: t('private_files_controller.not_found'), status: 404
  rescue UnknownTypeError
    logger.warn("#{Time.now} - Unknown type requested: #{params.inspect}")
    render text: t('private_files_controller.bad_request'), status: 400
  rescue PermissionDeniedError
    logger.warn("#{Time.now} - Permission Denied While Requesting Private Item: #{params.inspect}")
    render text: t('private_files_controller.unauthorized'), status: 401
  end
end
