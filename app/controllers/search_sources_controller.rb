class SearchSourcesController < ApplicationController

  before_filter :login_required, :only => [ :list, :index ]

  before_filter :set_page_title

  permit "site_admin"

  active_scaffold :search_sources do |config|
    config.label = I18n.t('search_sources_controller.title')

    config.columns = [:title, :source_type, :base_url, :more_link_base_url, :limit, :cache_interval]

    config.columns[:title].required = true
    config.columns[:title].description = I18n.t('search_sources_controller.source_title_description')

    config.columns[:source_type].required = true
    config.columns[:source_type].description = I18n.t('search_sources_controller.source_type_description')
    config.columns[:source_type].form_ui = :select
    config.columns[:source_type].options = SearchSource.acceptable_source_types.collect { |st| [st.humanize, st] }

    config.columns[:base_url].required = true
    config.columns[:base_url].description = I18n.t('search_sources_controller.source_base_url_description')

    config.columns[:more_link_base_url].label = I18n.t('search_sources_controller.source_more_link_base_url_label')
    config.columns[:more_link_base_url].description = I18n.t('search_sources_controller.source_more_link_base_url_description')

    config.columns[:limit].required = true
    config.columns[:limit].description = I18n.t('search_sources_controller.source_limit_description')

    config.columns[:cache_interval].required = true
    config.columns[:cache_interval].description = I18n.t('search_sources_controller.source_cache_interval_description')
  end

  private

  def set_page_title
    @title = t('search_sources_controller.title')
  end
end
