require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

class SearchSourcesController < ApplicationController
  unloadable

  before_filter ExternalSearchSources[:login_method]
  before_filter :redirect_if_not_authorized
  before_filter :set_page_title
  before_filter :get_search_source, :only => [ :move_higher, :move_lower ]
  before_filter :prepare_available_search_sources

  active_scaffold :search_sources do |config|
    config.label = I18n.t('search_sources_controller.title')

    list.sorting = { :position => 'ASC' }

    config.columns = [:title, :source_type, :source_target, :base_url, :more_link_base_url, :limit]
    config.columns << [:cache_interval] if ExternalSearchSources[:cache_results]
    config.list.columns.exclude [:source_type, :or_syntax, :more_link_base_url, :cache_interval]

    options = { :type => :record, :inline => false }
    # images_tag and @template.image_tag arn't available in this scope
    sort_arrow_up = "<img src='/images/arrow_up.gif' title='#{I18n.t('search_sources_controller.move_higher_title')}' alt='#{I18n.t('search_sources_controller.move_higher_title')}' style='border:none;' />"
    sort_arrow_down = "<img src='/images/arrow_down.gif' title='#{I18n.t('search_sources_controller.move_lower_title')}' alt='#{I18n.t('search_sources_controller.move_lower_title')}' style='border:none;' />"
    config.action_links.add sort_arrow_up, options.merge(:action => 'move_higher', :crud_type => :move_higher)
    config.action_links.add sort_arrow_down, options.merge(:action => 'move_lower', :crud_type => :move_lower)

    config.columns[:title].required = true
    config.columns[:title].description = I18n.t('search_sources_controller.source_title_description')

    config.columns[:source_type].required = true
    config.columns[:source_type].description = I18n.t('search_sources_controller.source_type_description')
    config.columns[:source_type].form_ui = :select
    config.columns[:source_type].options = SearchSource.acceptable_source_types.collect { |st| [st.humanize, st] }

    config.columns[:source_target].required = true
    config.columns[:source_target].description = I18n.t('search_sources_controller.source_target_description')
    config.columns[:source_target].form_ui = :select
    config.columns[:source_target].options = [['', '']] + SearchSource.acceptable_source_targets.collect { |st| [st.humanize, st] }

    config.columns[:base_url].required = true
    config.columns[:base_url].description = I18n.t('search_sources_controller.source_base_url_description')

    config.columns[:more_link_base_url].label = I18n.t('search_sources_controller.source_more_link_base_url_label')
    config.columns[:more_link_base_url].description = I18n.t('search_sources_controller.source_more_link_base_url_description')

    config.columns[:limit].description = I18n.t('search_sources_controller.source_limit_description')

    config.columns[:cache_interval].description = I18n.t('search_sources_controller.source_cache_interval_description')

    config.columns << [:or_syntax]
    config.columns[:or_syntax].label = I18n.t('search_sources_controller.or_syntax_label')
    config.columns[:or_syntax].description = I18n.t('search_sources_controller.or_syntax_description')
  end

  def move_higher
    @search_source.move_higher
    flash[:notice] = I18n.t('search_sources_controller.move_higher.moved_higher')
    redirect_to ExternalSearchSources[:default_url_options].merge(:action => 'list')
  end

  def move_lower
    @search_source.move_lower
    flash[:notice] = I18n.t('search_sources_controller.move_lower.moved_lower')
    redirect_to ExternalSearchSources[:default_url_options].merge(:action => 'list')
  end

  def install_search_source
    if params[:task]
      if @available_search_sources.include?(params[:task])
        old_search_source_count = SearchSource.count
        ENV['RAILS_ENV'] = RAILS_ENV
        rake_result = Rake::Task["external_search_sources:import:#{params[:task]}"].execute(ENV)
        if rake_result || SearchSource.count > old_search_source_count
          flash[:notice] = t('search_sources_controller.install_search_source.imported')
        else
          flash[:error] = t('search_sources_controller.install_search_source.problem_importing')
        end
      else
        flash[:error] = t('search_sources_controller.install_search_source.invalid_import')
      end
    else
      flash[:error] = t('search_sources_controller.install_search_source.no_import')
    end
    redirect_to ExternalSearchSources[:default_url_options].merge(:action => 'list')
  end

  private

  def authorized_to_access_search_sources?
    super
  rescue NoMethodError
    permit? ExternalSearchSources[:authorized_role]
  end

  def redirect_if_not_authorized
    super
  rescue NoMethodError
    unless authorized_to_access_search_sources?
      flash[:notice] = I18n.t('search_sources_controller.redirect_if_not_authorized.not_authorized')
      redirect_to ExternalSearchSources[:unauthorized_path]
    end
  end

  def get_search_source
    @search_source = SearchSource.find_by_id(params[:id])
  end

  def prepare_available_search_sources
    @available_search_sources = Rake.application.tasks.
                                 collect { |task| task.name =~ /external_search_sources:import:(\w+)$/ ? $1 : nil }.compact
  end

  # A method used by active scaffold before creating/updating a record
  # we have to set the or_syntax here ourselves because either rails or
  # active scaffold does not set or_syntax automatically when it is a hash
  def before_create_save(record)
    record.or_syntax = params[:record][:or_syntax]
  end

  def before_update_save(record)
    record.or_syntax = params[:record][:or_syntax]
  end

  def set_page_title
    @title = t('search_sources_controller.title')
  end
end
