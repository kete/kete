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
  def start_zebra
    `rake zebra:start`
    if !request.xhr?
      redirect_to :action => 'index', :search_engine_started => true, :search_engine_setup => true, :search_engine_show => true
    else
      render :update do |page|
        page.show('start-zebra-check')
        page.replace_html("start-zebra-message", "Search Engine started.  Stopping must be done by system administrator from command line.")
        page.hide('completed-message')
        page.show('finish')
      end
    end
  end

  def prime_zebra
    # initialize the databases first
    ['public', 'private'].each do |db|
      `rake zebra:init ZEBRA_DB=#{db}`
    end

    # load initial records (initializes attributes)
    `rake zebra:load_initial_records`

    ZOOM_CLASSES.each do |zoom_class|
      Module.class_eval(zoom_class).find(:all).each do |item|

        # Make sure that if the item is private, we store the private version and load the latest
        # public version into the master record so that OAI records are generated appropriately.
        if item.respond_to?(:private?) && item.private?
          logger.debug("Storing private version of #{item.id}.")
          item.send :store_correct_versions_after_save
          item.reload
        end

        # Generate OAI record and save to Zebra instances as appropriate.
        prepare_and_save_to_zoom(item)

      end
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
    site_listing
  end

  def send_information
    register_url = "http://kete.net.nz"
    kete_sites_link = register_url + "/site/kete_sites"
    register_new_link = "#{kete_sites_link}/new"
    if !request.xhr?
      redirect_to register_new_link
    else
      # this will break if reached when these constants aren't set
      raise "Pretty Site Name and Site URL constants are not set, are you sure you restarted your server after you configured your Kete site?" if SITE_URL.blank? || PRETTY_SITE_NAME.blank?
      begin
        register = RegisterSiteResource.create(:name => PRETTY_SITE_NAME, :url => SITE_URL, :description => params[:site_description])
      rescue
        register = nil
        @register_error = $!
      end
      render :update do |page|
        top_message = String.new
        if !register.nil? && register && register.errors.empty? && register.id > 0
          top_message = "Your Kete installation has been registered. Thank you. You can view the whole directory of Kete sites at " + link_to(kete_sites_link) + "."
        elsif !register.nil? && !register.errors.empty?
          register_message = "<strong>Some fields were incorrect:</strong><br />"
          register.errors.each do |field, error|
            register_message += "&nbsp;&nbsp;#{field.humanize} #{error}<br />"
          end
          message += "<br />"
          page.replace_html("register_errors", register_message)
          page.show('form_fields')
          page.show('site_description')
          page.show('data-button')
          page.hide('top_message')
        else
          logger.error("Error linking from Kete.net.nz: " + @register_error) if @register_error
          top_message = "There was an error linking to your site. "
          site_listing
          if @site_listing.blank?
            top_message += "You can do it manually at "+ link_to(register_new_link) + "."
          else
            top_message += "However, it appears that your site is now listed. Please check the listing to make sure it is correct at " + link_to(@site_listing) + '.'
          end
        end
        page.replace_html("top_message", top_message)
      end
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

  def site_listing
    # we empty @site_listing in case it already exists
    @site_listing = String.new
    require 'net/http'
    require 'uri'
    remote_url = URI.parse("http://kete.net.nz/site/kete_sites/has_link_to")
    remote_url.path = "/" if remote_url.path.length < 1
    http = Net::HTTP.new(remote_url.host, 80)
    @site_listing = http.request_post(remote_url.path, "url=#{SITE_URL}").body
  end

  helper_method :site_listing

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

class RegisterSiteResource < ActiveResource::Base
  self.site = "http://kete.net.nz/site/"
  self.element_name = "kete_site"
  self.timeout = 60
end
