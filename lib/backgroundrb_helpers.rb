module BackgroundrbHelpers
  unless included_modules.include? BackgroundrbHelpers

    def backgroundrb_started?
      started = true
      begin
        MiddleMan.new_worker
      rescue
        started = false
        # we log that backgroundrb is not running
        Rails.logger.info('Backgroundrb is not running when it should be. Make sure to get it going again!')
      end
      started
    end

    def backgroundrb_running_for?(worker_type, worker_key)
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

    def backgroundrb_delete_existing_workers_for(worker_type, worker_key, with_delay = true)
      if backgroundrb_is_running?(worker_type, worker_key)
        MiddleMan.worker(worker_type.to_sym, worker_key.to_s).delete
        sleep 5 if with_delay # give it time to kill the worker
      end
    end
  end
end
