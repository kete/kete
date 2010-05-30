# used by controllers that manage backgroundrb workers
module WorkerControllerHelpers
  unless included_modules.include? WorkerControllerHelpers

    # in order to prevent conflicts from other Kete installations on the same host
    # we need to add a site name prefix to our worker key
    def worker_key_for(worker_type)
      SITE_URL.split('//')[1].chomp('/').gsub(/\W/, '_') + "_" + worker_type.to_s
    end

    def backgroundrb_is_running?(worker_type, worker_key = nil)
      worker_key = worker_key || worker_key_for(worker_type)
      is_running = false
      MiddleMan.all_worker_info.each do |server|
        if !server[1].nil?
          server[1].each { |workers| is_running = true if (worker_type.to_sym == workers[:worker] &&
                                                           (workers[:worker_key].blank? ||
                                                            worker_key.to_s == workers[:worker_key])) }
        end
        break if is_running
      end
      is_running
    end

    def delete_existing_workers_for(worker_type, worker_key = nil, with_delay = true)
      worker_key = worker_key || worker_key_for(worker_type)
      if backgroundrb_is_running?(worker_type, worker_key)
        MiddleMan.worker(worker_type.to_sym, worker_key.to_s).delete
        sleep 5 if with_delay # give it time to kill the worker
      end
    end

    # this takes the configuration and uses it to start a backgroundrb worker
    # to do the actual rebuild work on zebra
    def rebuild_zoom_index
      @zoom_class = !params[:zoom_class].blank? ? params[:zoom_class] : 'all'
      @start_id = !params[:start].blank? && @zoom_class != 'all' ? params[:start] : 'first'
      @end_id = !params[:end].blank? && @zoom_class != 'all' ? params[:end] : 'last'
      @skip_existing = !params[:skip_existing].blank? ? params[:skip_existing] : false
      @skip_private = !params[:skip_private].blank? ? params[:skip_private] : false
      @clear_zebra = !params[:clear_zebra].blank? ? params[:clear_zebra] : false

      @worker_type = 'zoom_index_rebuild_worker'
      @worker_key ||= worker_key_for(@worker_type)

      import_request = { :host => request.host,
        :protocol => request.protocol,
        :request_uri => request.request_uri }

      @worker_running = false
      # only one rebuild should be running at a time
      unless backgroundrb_is_running?(@worker_type)
        MiddleMan.new_worker( :worker => @worker_type, :worker_key => @worker_key )
        MiddleMan.worker(@worker_type, @worker_key).async_do_work( :arg => { :zoom_class => @zoom_class,
                                                                           :start_id => @start_id,
                                                                           :end_id => @end_id,
                                                                           :skip_existing => @skip_existing,
                                                                           :skip_private => @skip_private,
                                                                           :clear_zebra => @clear_zebra,
                                                                           :import_request => import_request } )
        @worker_running = true
      else
        flash[:notice] = I18n.t('worker_controller_helpers_lib.rebuild_zoom_index.aready_rebuilding')
      end
    end
  end
end
