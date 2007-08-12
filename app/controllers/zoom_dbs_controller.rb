class ZoomDbsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "tech_admin of :site"

  active_scaffold :zoom_db do |config|
    list.columns.exclude [:updated_at, :created_at, :zoom_password]
  end
end
