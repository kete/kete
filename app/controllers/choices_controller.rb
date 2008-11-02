class ChoicesController < ApplicationController
  
  before_filter :login_required, :only => [ :list, :index ]
  
  permit "site_admin"
  
  active_scaffold :choices do |config|
    
    # Which columns to show
    config.columns = [:label, :value, :parent]
    config.list.columns.exclude :updated_at, :created_at
    
    # Column overrides
    config.columns[:label].required = true
    config.columns[:value].description = "Label will be used as value if left blank."
    
    # Subform column overrides
    # config.subform.columns = [:label]
  end
  
end