# frozen_string_literal: true

module MayBeUploadAsServiceController
  unless included_modules.include? MayBeUploadAsServiceController
    def self.included(klass)
      klass.send :layout, :simple_for_as_service_else_application
    end

    private

    def simple_for_as_service_else_application
      if params[:as_service].present? && params[:as_service] == 'true'
        'simple'
      else
        'application'
      end
    end
  end
end
