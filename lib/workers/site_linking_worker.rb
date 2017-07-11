class SiteLinkingWorker < BackgrounDRb::MetaWorker
  set_worker_name :site_linking_worker
  set_no_auto_load true

  include SiteLinking

  def create(args = nil)
    results = { linking_success: false,
                linking_validation_errors: Array.new,
                linking_complete: false }

    cache[:results] = results
  end

  def do_work(args = nil)
    results = cache[:results]
    params = args[:params]

    check_nessesary_constants_set

    begin
      linking = SiteLinkingResource.create(
        name: SystemSetting.pretty_site_name,
        url: SystemSetting.full_site_url,
        description: params[:site_description],
        address: params[:site_publisher_address]
      )
    rescue
      linking = nil
      kete_net_error = $!
    end

    if !linking.nil? && linking && linking.errors.empty? && linking.id > 0
      results[:linking_success] = true
    elsif !linking.nil? && !linking.errors.empty?
      results[:linking_validation_errors] = linking.errors
    else
      logger.error('Error linking from Kete.net.nz: ' + kete_net_error) if kete_net_error
    end

    results[:linking_complete] = true

    cache[:results] = results
  end

  def reset_worker
    results = { linking_success: false,
                linking_validation_errors: Array.new,
                linking_complete: false }

    cache[:results] = results
  end

end
