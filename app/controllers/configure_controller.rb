class ConfigureController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:section, :finish,
                                           :done_with_settings, :zoom_dbs_edit,
                                           :zoom_dbs_update, :start_zebra,
                                           :index]

  permit "tech_admin of :site"

  include SiteLinking

  def index
    @advanced = params[:advanced] || false
    @sections = SETUP_SECTIONS.collect { |s| s}
    if @advanced
      SystemSetting.find(:all,
                         :select => 'distinct section',
                         :conditions => ["technically_advanced = :technically_advanced and section not in (:sections)",
                                         { :technically_advanced => true,
                                           :sections => @sections }]).each { |advanced_section| @sections << advanced_section.section }
    end
    @admin_password_changed = User.find(1).crypted_password != '00742970dc9e6319f8019fd54864d3ea740f04b1' ? true : false

    @ready_to_restart = params[:ready_to_restart] || false
    @finished = params[:finished] || false

    stub = "search_engine_"
    ['show', 'setup', 'started', 'primed'].each do |step|
      var_name = stub + step
      instance_variable_set("@#{var_name}", params[var_name.to_sym] || false)
    end
    set_not_completed
  end

  def section
    @section = params[:section]
    @advanced = params[:advanced]
    @settings = SystemSetting.find_all_by_section(@section)
    if request.xhr?
      flash[:notice] = nil
      render :layout => false
    else
      render
    end
  end

  def update
    @section = params[:section]

    @settings = SystemSetting.find_all_by_section(@section).each {  |s| s.value = params[:setting][s.id.to_s][:value] }

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
        redirect_to :action => 'index'
      end
    else
      @has_errors = true
      if !request.xhr?
        render :action => 'section'
      else
        @section_html = render_to_string :action => 'section', :layout => false
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
      redirect_to :action => 'index', :search_engine_show => true
    else
      render :update do |page|
        page.hide("settings")
        page.show("zoom")
        page.replace_html("completed-message", "<h3>Not yet completed.</h3>")
      end
    end
  end

  def zoom_dbs_edit
    @zoom_dbs = ZoomDb.find(:all)
    @kete_password = @zoom_dbs.first.zoom_password
    if request.xhr?
      render :layout => false
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
    @zoom_dbs = ZoomDb.find(:all).each do |zoom_db|
      zoom_db.zoom_password = @kete_password
      zoom_db.port = params[:zoom_db][zoom_db.id.to_s][:port]
    end

    # run validations
    @zoom_dbs.each(&:valid?)

    @has_errors = false
    if @zoom_dbs.all? { |zoom_db| zoom_db.errors.empty? and !@kete_password.blank? }

      ENV['ZEBRA_PASSWORD'] = @kete_password
      `rake zebra:set_keteaccess`

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

      `rake zebra:set_ports`
      ENV.delete 'PUBLIC_PORT'
      ENV.delete 'PRIVATE_PORT'

      if !request.xhr?
        redirect_to :action => 'index', :search_engine_setup => true, :search_engine_show => true
      end
    else
      @has_errors = true
      if !request.xhr?
        render :action => 'zoom_dbs_edit'
      else
        @zoom_dbs_html = render_to_string :action => 'zoom_dbs_edit', :layout => false
      end
    end
  end

  # note that you can also rebuild your zebra instance later
  # from the 'Rebuild search databases' administrator toolbox link

  # actions for rebuilding search records
  include WorkerControllerHelpers

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
      redirect_to :action => 'index', :search_engine_primed => true, :search_engine_show => true, :finished => true
    else
      # check to see if the site is already listed
      # loads variable used in the reload-site-index section
      site_listing

      render :update do |page|
        page.show('prime-zebra-check')
        page.replace_html("prime-zebra-message", "Search Engine has been primed.")
        page.show('reload-site-index')
        page.hide('restart-before-continue-message')
      end
    end
  end

  # basically a container action
  # to reuse the link_to_site partial
  # that we also at site configure in index
  def add_link_from_kete_net
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
        @worker_type = "site_linking_worker".to_sym
        @worker_key = worker_key_for(@worker_type)

        # if the site registration never completed, this worker may still be operational
        # (that should only happen when bgrb returns nothing, caused by errors in the worker)
        # so we use this method to attempt to delete it (before starting another)
        delete_existing_workers_for(@worker_type)

        unless backgroundrb_is_running?(@worker_type)
          MiddleMan.new_worker( :worker => @worker_type, :worker_key => @worker_key )
          MiddleMan.worker(@worker_type, @worker_key).async_do_work( :arg => { :params => params } )
          render :update do |page|
            page.replace_html("updater", periodically_call_remote(:url => { :action => 'get_site_linking_progress' }, :frequency => 3))
          end
        else
          render :update do |page|
            page.replace_html("top_message", "There is already a site registration worker active. Wierd! Try refreshing the page.")
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
      @worker_type = "site_linking_worker".to_sym
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
            top_message = "Your Kete installation has been registered. Thank you. You can view the whole directory of Kete sites at <a href='#{@kete_sites}'>#{@kete_sites}</a>."
            render :update do |page|
              page.hide('spinner')
              page.replace_html("top_message", top_message)
            end
          elsif !status[:linking_validation_errors].blank?
            linking_errors = "<strong>Some fields were incorrect:</strong><br />"
            status[:linking_validation_errors].each do |field, error|
              linking_errors += "&nbsp;&nbsp;#{field.humanize} #{error}<br />"
            end
            render :update do |page|
              page.replace_html("linking_errors", linking_errors)
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
    raise "Not all settings have been filled out." if @not_completed
    @is_configured_setting = SystemSetting.find(1)
    @is_configured_setting.value = 'true'
    @success = @is_configured_setting.save
    if @success and !request.xhr?
        redirect_to :action => 'index', :ready_to_restart => :true
    end
  end

  def set_not_completed
    @not_completed = SystemSetting.not_completed
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
