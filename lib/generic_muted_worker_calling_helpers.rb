# convenience methods to DRY up calling generic muted worker
module GenericMutedWorkerCallingHelpers
  unless included_modules.include? GenericMutedWorkerCallingHelpers
    include WorkerControllerHelpers

    def call_generic_muted_worker_with(options)
      return false if Rails.env == 'test'

      method_name = options.delete(:method_name)
      raise unless method_name

      worker_type = :generic_muted_worker

      the_worker_name = worker_name_for(stub: method_name,
                                        key: key_parts_from(options))

      class_key = options.delete(:class_key)
      the_object = options.delete(:object)

      options = options.merge({ class_key => the_object }) if class_key

      logger.debug('what are worker options ' + options.inspect)

      worker_key = worker_key_for(the_worker_name).to_s

      options.delete(class_key)

      # TODO: replace this by queueing
      # we want the latest call to run, delete previous calls
      if backgroundrb_is_running?(worker_type, worker_key)
        delete_existing_workers_for(worker_type, worker_key)
      end

      backgroundrb_worker_started = false
      if backgroundrb_started?
        # only allow a single generic worker called with the same key to happen at once
        MiddleMan.new_worker(worker: worker_type,
                             worker_key: worker_key)

        logger.debug('what is worker_key: ' + worker_key.inspect)
        logger.debug('what are worker options last ' + options.inspect)

        MiddleMan.worker(worker_type,
                         worker_key).async_do_work(arg: {
                                                     method_name: method_name,
                                                     options: options
                                                   })

        backgroundrb_worker_started = true
      end

      backgroundrb_worker_started
    end
  end
end
