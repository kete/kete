class SiteRegistrationWorker < BackgrounDRb::MetaWorker
  set_worker_name :site_registration_worker
  set_no_auto_load true

  include SiteRegistration

  def create(args = nil)
    results = { :registration_success => false,
                :registration_validation_errors => Array.new,
                :registration_complete => false }

    cache[:results] = results
  end

  def do_work(args = nil)
    @results = cache[:results]
    params = args[:params]

    check_nessesary_constants_set

    begin
      register = RegisterSiteResource.create(:name => PRETTY_SITE_NAME, :url => SITE_URL, :description => params[:site_description])
    rescue
      register = nil
      @kete_net_error = $!
    end

    if !register.nil? && register && register.errors.empty? && register.id > 0
      @results[:registration_success] = true
    elsif !register.nil? && !register.errors.empty?
      @results[:registration_validation_errors] = register.errors
    else
      logger.error("Error linking from Kete.net.nz: " + @kete_net_error) if @kete_net_error
    end

    @results[:registration_complete] = true

    cache[:results] = @results
  end

  def reset_worker
    results = { :registration_success => false,
                :registration_validation_errors => Array.new,
                :registration_complete => false }

    cache[:results] = results
  end

end
