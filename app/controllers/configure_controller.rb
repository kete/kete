class ConfigureController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:section, :finish,
                                           :done_with_settings, :zoom_dbs_edit,
                                           :zoom_dbs_update, :start_zebra,
                                           :index]

  permit "tech_admin of :site"

  def index
    @advanced = params[:advanced] || false
    @sections = SETUP_SECTIONS.collect { |s| s}
    if @advanced
      SystemSetting.find(:all,
                         :select => 'distinct section',
                         :conditions => ["technically_advanced = 1 and section not in (?)",
                                         @sections]).each { |advanced_section| @sections << advanced_section.section }
    end
    @admin_password_changed = User.find(1).crypted_password != '00742970dc9e6319f8019fd54864d3ea740f04b1' ? true : false

    @ready_to_restart = params[:ready_to_restart] || false
    @finished = params[:finished] || false

    stub = "search_engine_"
    ['show', 'setup', 'started', 'primed'].each do |step|
      var_name = stub + step
      instance_variable_set("@#{var_name}", params[var_name.to_sym] || false)
    end

    @not_completed = SystemSetting.count(:conditions => "required_to_be_configured = 1 and value is null") > 0 ? true : false
  end

  def section
    @section = params[:section]
    @advanced = params[:advanced]
    @settings = SystemSetting.find_all_by_section(@section)
    if request.xhr?
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

    @not_completed = SystemSetting.count(:conditions => "required_to_be_configured = 1 and value is null") > 0 ? true : false

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

  def start_zebra
    `rake zebra:start`
    if !request.xhr?
      redirect_to :action => 'index', :search_engine_started => true, :search_engine_setup => true, :search_engine_show => true
    else
      render :update do |page|
        page.show('start-zebra-check')
        page.replace_html("start-zebra-message", "Search Engine started.  Stopping must be done by system administrator from command line.")
        page.show('prime-zebra-message')
      end
    end
  end

  def prime_zebra
    # initialize the databases first
    ['public', 'private'].each do |db|
      `rake zebra:init ZEBRA_DB=#{db}`
    end

    ZOOM_CLASSES.each do |zoom_class|
      Module.class_eval(zoom_class).find(:all).each { |item| prepare_and_save_to_zoom(item) }
    end

    if !request.xhr?
      redirect_to :action => 'index', :search_engine_primed => true, :search_engine_show => true, :finished => true
    else
      render :update do |page|
        page.show('prime-zebra-check')
        page.replace_html("prime-zebra-message", "Search Engine has been primed.")
        page.hide('completed-message')
        page.show('finish')
      end
    end
  end

  # update the "Is Configured" system setting
  # if all required settings are supplied
  def finish
    @not_completed = SystemSetting.count(:conditions => "required_to_be_configured = 1 and value is null") > 0 ? true : false
    raise "Not all settings have been filled out." if @not_completed
    @is_configured_setting = SystemSetting.find(1)
    @is_configured_setting.value = true
    @success = @is_configured_setting.save
    if @success and !request.xhr?
        redirect_to :action => 'index', :ready_to_restart => :true
    end
  end
end
