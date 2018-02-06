# frozen_string_literal: true

module DefaultUrlOptions
  unless included_modules.include? DefaultUrlOptions

    # EOIN: ROB: we are pretty sure we don't need this
    # Sets the host for all url_for calls
    # def default_url_options(options = nil)
    #   (defined?(SystemSetting.site_name) && SystemSetting.site_name.present?) ? { :host => SystemSetting.site_name } : {}
    # end
  end
end
