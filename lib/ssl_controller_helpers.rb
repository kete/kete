# frozen_string_literal: true

module SslControllerHelpers
  unless included_modules.include? SslControllerHelpers

    def ssl_required?
      SystemSetting.force_https_on_restricted_pages || false
    end

    # If ssl_allowed? returns true, the SSL requirement is not enforced,
    # so ensure it is not set in this controller.
    def ssl_allowed?
      nil
    end

  end
end
