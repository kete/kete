class SystemSettingsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, only: [:list, :index]

  permit 'tech_admin of :site'

  # active_scaffold :system_setting do |config|
  #   config.label = 'System Settings: server restart required to take effect'
  #   config.columns = [:name, :section, :value, :explanation, :technically_advanced, :required_to_be_configured]
  #   list.columns.exclude [:updated_at, :created_at]
  #   list.sorting = { :section => 'ASC'}
  # end

  private
  include SslControllerHelpers
end
