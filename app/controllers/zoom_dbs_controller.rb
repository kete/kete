class ZoomDbsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "tech_admin of :site"

  active_scaffold :zoom_db do |config|
    list.columns.exclude [:updated_at, :created_at, :zoom_password]
  end
  
  private
  
    def ssl_required?
      FORCE_HTTPS_ON_RESTRICTED_PAGES || false
    end
    
    # If ssl_allowed? returns true, the SSL requirement is not enforced,
    # so ensure it is not set in this controller.
    def ssl_allowed?
      nil
    end
    
end
