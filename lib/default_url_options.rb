module DefaultUrlOptions
  unless included_modules.include? DefaultUrlOptions
    # Sets the host for all url_for calls
    def default_url_options(options = nil)
      (defined?(Kete.site_name) && Kete.site_name.present?) ? { :host => Kete.site_name } : {}
    end
  end
end
