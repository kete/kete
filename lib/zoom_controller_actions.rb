module ZoomControllerActions
  unless included_modules.include? ZoomControllerActions
    include WorkerControllerHelpers

    # this takes the configuration and uses it to start a backgroundrb worker
    # to do the actual rebuild work on zebra
    def rebuild_zoom_index
      @zoom_class = params[:zoom_class].present? ? params[:zoom_class] : 'all'
      @start_id = params[:start].present? && @zoom_class != 'all' ? params[:start] : 'first'
      @end_id = params[:end].present? && @zoom_class != 'all' ? params[:end] : 'last'
      @skip_existing = params[:skip_existing].present? ? params[:skip_existing] : false
      @skip_private = params[:skip_private].present? ? params[:skip_private] : false
      @clear_zebra = params[:clear_zebra].present? ? params[:clear_zebra] : false

      @worker_type = 'zoom_index_rebuild_worker'
      @worker_key ||= worker_key_for(@worker_type)

      import_request = { host: request.host,
        protocol: request.protocol,
        request_uri: request.original_url }

      @worker_running = false
      # only one rebuild should be running at a time
      unless backgroundrb_is_running?(@worker_type)
        MiddleMan.new_worker( worker: @worker_type, worker_key: @worker_key )

        MiddleMan.worker(@worker_type, @worker_key).async_do_work( arg: {
                                                                     zoom_class: @zoom_class,
                                                                     start_id: @start_id,
                                                                     end_id: @end_id,
                                                                     skip_existing: @skip_existing,
                                                                     skip_private: @skip_private,
                                                                     clear_zebra: @clear_zebra,
                                                                     import_request: import_request } )
        @worker_running = true
      else
        flash[:notice] = I18n.t('worker_controller_helpers_lib.rebuild_zoom_index.aready_rebuilding')
      end
    end
  end
end
