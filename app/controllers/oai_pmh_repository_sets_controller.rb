class OaiPmhRepositorySetsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]
  before_filter :set_page_title

  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :oai_pmh_repository_set do |config|
    config.columns = [:zoom_db, :name, :set_spec, :description, :active, :match_code, :value, :dynamic]
    config.columns[:zoom_db].form_ui = :select
    list.columns.exclude [:updated_at, :created_at]
  end

  private

  def set_page_title
    @title = t('oai_pmh_repository_sets_controller.title')
  end
end
