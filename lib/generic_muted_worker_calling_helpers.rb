# convenience methods to DRY up calling generic muted worker
module GenericMutedWorkerCallingHelpers
  unless included_modules.include? GenericMutedWorkerCallingHelpers
    include WorkerControllerHelpers

    # the convention is that object
    def call_generic_muted_worker_with(options)
      method_name = options.delete(:method_name)
      raise unless method_name

      class_key = options.delete(:class_key)
      the_object = options.delete(:object)

      worker_type = :generic_muted_worker

      the_worker_name = "generic_muted_worker_#{method_name}"

      if class_key
        the_worker_name += "_#{class_key}_#{the_object.id}"
        options = options.merge({ class_key => the_object })
      else
        the_worker_name += "_#{Time.now.to_i}"
      end

      worker_key = worker_key_for(the_worker_name)

      # only allow a single cache clearing to happen at once
      MiddleMan.new_worker( :worker => worker_type,
                            :worker_key => worker_key )
    
      MiddleMan.worker(worker_type, worker_key).async_do_work( :arg => { :method_name => method_name, :options => options } )
      true
    end
  end
end
