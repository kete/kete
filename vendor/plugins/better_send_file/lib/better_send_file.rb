module BetterSendFile
  
  include Backends::NginxProxyBackend 

  # Send a file through a front-end proxy
  # Path should be path from RAILS_ROOT
  # i.e. /private/some_file.gif would send the file at RAILS_ROOT/private/some_file.gif.
  
  # Valid options are:
  # :type         Setting for Content-Type header (defaults to force-download)
  # :disposition  Setting for Content-Disposition header (defaults to 'attachment')
  # :filename     Setting for Content-Disposition header (defaults to File.basename(file))
  def send_file(path, original_options = {})
    
    # Set up options
    default_options = {
      :type         =>  "application/force-download",
      :filename     =>  File.basename(File.join(RAILS_ROOT, path)),
      :disposition  =>  "attachment",
      :status       =>  200,
      :stream       =>  true,
      :buffer_size  =>  4096
    }

    options = default_options.merge(original_options)
    
    send_file_via_proxy(path, options)
    
  rescue
    super path, original_options
  end
  
end