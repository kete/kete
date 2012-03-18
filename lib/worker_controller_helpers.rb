# used by controllers that manage backgroundrb workers
module WorkerControllerHelpers
  unless included_modules.include? WorkerControllerHelpers

    # in order to prevent conflicts from other Kete installations on the same host
    # we need to add a site name prefix to our worker key
    def worker_key_for(worker_type)
      Kete.site_name.gsub(/\W/, '_') + "_" + worker_type.to_s
    end

    def key_parts_from(options)
      if options[:class_key]
        [options[:class_key], options[:object].id]
      else
        Time.now.to_i.to_s
      end
    end

    def worker_name_for(options)
      stub = options[:stub]
      key = options[:key]

      parts = stub.present? ? [stub] : Array.new

      if key.is_a?(Array)
        parts += key
      else
        parts << key
      end

      parts.join('_')
    end

    def backgroundrb_started?
      started = true
      begin
        MiddleMan.new_worker
      rescue
        started = false
      end
      started
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
      worker_key ||= worker_key_for(worker_type)

      if backgroundrb_is_running?(worker_type, worker_key)
        MiddleMan.worker(worker_type.to_sym, worker_key.to_s).delete
        sleep 5 if with_delay # give it time to kill the worker
      end
    end
  end
end
