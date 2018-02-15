require 'rake'
# require 'rake/rdoctask'
# require 'rake/testtask'

class ConfigureController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, only: %i[
    section finish
    done_with_settings zoom_dbs_edit
    zoom_dbs_update start_zebra
    index
]

  permit 'tech_admin of :site'
  permit 'site_admin of :site', only: %i[add_link_to_kete_net send_information get_site_linking_progress]

  include SiteLinking

  def index
    @advanced = params[:advanced] || false
    @sections = SystemSetting.setup_sections.collect { |s| s }
    if @advanced
      SystemSetting.select(:section).distinct.where('technically_advanced = ? and section not in (?)', true, @sections).each { |advanced_section| @sections << advanced_section.section }
    end
    @admin_password_changed = User.find(1).crypted_password != '00742970dc9e6319f8019fd54864d3ea740f04b1'

    @ready_to_restart = params[:ready_to_restart] || false
    @finished = params[:finished] || false

    stub = 'search_engine_'
    ['show', 'setup', 'started', 'primed'].each do |step|
      var_name = stub + step
      instance_variable_set("@#{var_name}", params[var_name.to_sym] || false)
    end
    set_not_completed
  end

  def section
    @section = params[:section]
    @advanced = params[:advanced]
    @settings = SystemSetting.where(section: @section)
    if request.xhr?
      flash[:notice] = nil
      render layout: false
    else
      render
    end
  end

  def update
    @section = params[:section]

    @settings = SystemSetting.where(section: @section).each { |s| s.value = params[:setting][s.id.to_s][:value] }

    # run validations
    @settings.each(&:valid?)

    # we use a non-validate method, since required_to_be_configured
    # is only really necessary in this controller
    @settings.each { |s| s.add_error_if_required }

    set_not_completed

    @has_errors = false
    if @settings.all? { |s| s.errors.empty? }
      @settings.each(&:save!)
      if !request.xhr?
        redirect_to action: 'index'
      end
    else
      @has_errors = true
      if !request.xhr?
        render action: 'section'
      else
        @section_html = render_to_string action: 'section', layout: false
      end
    end
  end

  # section
  # section update
  # password setting for admin account and zoom_dbs
  # populate public zoom_db
  # finish - marks site as configured
  # index page with reminder of restart, steps after restart -
  #  * settings for site basket
  #  * write homepage topic
  #  * edit your about and help sections

  def done_with_settings
    if !request.xhr?
      redirect_to action: 'index', search_engine_show: true
    else
      render :update do |page|
        page.hide('settings')
        page.show('zoom')
        page.replace_html('completed-message', "<h3>#{t('configure_controller.done_with_settings.not_yet_completed')}</h3>")
      end
    end
  end

  def zoom_dbs_edit
    @zoom_dbs = ZoomDb.all
    @kete_password = @zoom_dbs.first.zoom_password
    if request.xhr?
      render layout: false
    else
      render
    end
  end

  def zoom_dbs_update
    # TODO: add kill of running zebra instance if possible
    # zebrasrv logs pid in log/zebra.log
    # however zebrasrv spawns processes
    # so killing that pid is usually not enough

    @kete_password = params[:kete_password]
    @zoom_dbs =
      ZoomDb.all.each do |zoom_db|
        zoom_db.zoom_password = @kete_password
        zoom_db.port = params[:zoom_db][zoom_db.id.to_s][:port]
      end

    # run validations
    @zoom_dbs.each(&:valid?)

    @has_errors = false
    if @zoom_dbs.all? { |zoom_db| zoom_db.errors.empty? && !@kete_password.blank? }

      ENV['ZEBRA_PASSWORD'] = @kete_password
      Rails.logger.info Rake::Task['zebra:set_keteaccess'].execute(ENV)

      @zoom_dbs.each do |zoom_db|
        zoom_db.save!

        # set up the writing of ports out to config file
        case zoom_db.database_name
        when 'public'
          ENV['PUBLIC_PORT'] = zoom_db.port
        when 'private'
          ENV['PRIVATE_PORT'] = zoom_db.port
        end
      end

      Rails.logger.info Rake::Task['zebra:set_ports'].execute(ENV)
      ENV.delete 'PUBLIC_PORT'
      ENV.delete 'PRIVATE_PORT'

      if !request.xhr?
        redirect_to action: 'index', search_engine_setup: true, search_engine_show: true
      end
    else
      @has_errors = true
      if !request.xhr?
        render action: 'zoom_dbs_edit'
      else
        @zoom_dbs_html = render_to_string action: 'zoom_dbs_edit', layout: false
      end
    end
  end

  # note that you can also rebuild your zebra instance later
  # from the 'Rebuild search databases' administrator toolbox link

  # actions for rebuilding search records
  include ZoomControllerActions

  def prime_zebra
    # consolidating the code to do this work by using existing worker
    params[:clear_zebra] = true
    rebuild_zoom_index

    status = MiddleMan.worker(@worker_type, @worker_key).ask_result(:results)
    while status.blank? || status[:done_with_do_work] != true
      sleep 5
      status = MiddleMan.worker(@worker_type, @worker_key).ask_result(:results)
    end

    if !request.xhr?
      redirect_to action: 'index', search_engine_primed: true, search_engine_show: true, finished: true
    else
      # check to see if the site is already listed
      # loads variable used in the reload-site-index section
      site_listing

      render :update do |page|
        page.show('prime-zebra-check')
        page.replace_html('prime-zebra-message', t('configure_controller.prime_zebra.primed_zebra'))
        page.show('reload-site-index')
        page.hide('restart-before-continue-message')
      end
    end
  end

  # basically a container action
  # to reuse the link_to_site partial
  # that we also at site configure in index
  def add_link_to_kete_net
    # check to see if the site is already listed
    # loads variable used in the reload-site-index section
    site_listing
  end

  def send_information
    set_kete_net_urls
    if !request.xhr?
      redirect_to @new_kete_site
    else
      begin
        @worker_type = 'site_linking_worker'.to_sym
        @worker_key = worker_key_for(@worker_type)

        # if the site registration never completed, this worker may still be operational
        # (that should only happen when bgrb returns nothing, caused by errors in the worker)
        # so we use this method to attempt to delete it (before starting another)
        delete_existing_workers_for(@worker_type)

        unless backgroundrb_is_running?(@worker_type)
          MiddleMan.new_worker(worker: @worker_type, worker_key: @worker_key)
          MiddleMan.worker(@worker_type, @worker_key).async_do_work(arg: { params: params })
          render :update do |page|
            page.replace_html('updater', periodically_call_remote(url: { action: 'get_site_linking_progress' }, frequency: 10))
          end
        else
          render :update do |page|
            page.replace_html('top_message', t('configure_controller.send_information.already_running'))
            page.hide('spinner')
          end
        end
      rescue
        error_linking_site
      end
    end
  end

  def get_site_linking_progress
    set_kete_net_urls
    begin
      @worker_type = 'site_linking_worker'.to_sym
      @worker_key = worker_key_for(@worker_type)
      status = MiddleMan.worker(@worker_type, @worker_key).ask_result(:results)
      logger.debug(status.inspect)
      if !status.blank?
        if status[:linking_complete] == true
          # the following lines means the periodic calls to this method wont cause errors
          # when trying to process the registration again
          MiddleMan.worker(@worker_type, @worker_key).reset_worker
          MiddleMan.worker(@worker_type, @worker_key).delete

          if status[:linking_success] == true
            top_message = t(
              'configure_controller.get_site_linking_progress.site_registered',
              kete_sites_link: @kete_sites
            )
            render :update do |page|
              page.hide('spinner')
              page.replace_html('updater', '')
              page.replace_html('top_message', top_message)
            end
          elsif !status[:linking_validation_errors].blank?
            linking_errors = "<strong>#{t('configure_controller.get_site_linking_progress.incorrect_fields')}</strong><br />"
            status[:linking_validation_errors].each do |field, error|
              linking_errors += "&nbsp;&nbsp;#{field.humanize} #{error}<br />"
            end
            render :update do |page|
              page.replace_html('updater', '')
              page.replace_html('linking_errors', linking_errors)
              page.hide('spinner')
              page.show('form_fields')
            end
          else
            error_linking_site
          end
        else
          render :update do |page| # we don't update anything, this just silenses errors
          end
        end
      else
        error_linking_site
      end
    rescue
      error_linking_site
    end
  end

  # update the "Is Configured" system setting
  # if all required settings are supplied
  def finish
    set_not_completed
    raise 'Not all settings have been filled out.' if @not_completed
    @is_configured_setting = SystemSetting.find_by_name('Is Configured')
    @is_configured_setting.value = 'true'
    @success = @is_configured_setting.save
    if @success && !request.xhr?
      redirect_to action: 'index', ready_to_restart: :true
    end
  end

  def set_not_completed
    @not_completed = SystemSetting.not_completed
  end

  # controls once the site is configured

  def restart_server
    ENV['RAILS_ENV'] = Rails.env
    rake_result = Rake::Task['kete:tools:restart'].execute(ENV)
    if rake_result
      flash[:notice] = t('configure_controller.restart_server.server_restarted')
    else
      flash[:error] = t('configure_controller.restart_server.problem_restarting')
    end
    redirect_to urlified_name: @site_basket.urlified_name, controller: 'configure', action: 'index'
  end

  def clear_cache
    ENV['RAILS_ENV'] = Rails.env
    rake_result = Rake::Task['tmp:cache:clear'].execute(ENV)
    if rake_result
      flash[:notice] = t('configure_controller.clear_cache.cache_cleared')
    else
      flash[:error] = t('configure_controller.clear_cache.problem_clearing_cache')
    end
    redirect_to urlified_name: @site_basket.urlified_name, controller: 'configure', action: 'index'
  end

  private

  include SslControllerHelpers
end
