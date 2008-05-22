class LicensesController < ApplicationController

  before_filter :login_required
  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :license do |config|
    config.columns = [:name, :description, :url, :image_url, :metadata, :is_available, :is_creative_commons]
    list.columns.exclude [:updated_at, :created_at, :metadata, :description, :image_url, :is_available, :is_creative_commons, :users]
  end

end
