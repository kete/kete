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

      # TODO: dry up stub here and in lib/zoom_controller_helpers.rb
      the_worker_name = worker_name_for(:stub => "#{worker_type}_#{method_name}",
                                        :key => key_parts_from(options))

      options = options.merge({ class_key => the_object }) if class_key


      worker_key = worker_key_for(the_worker_name)

      # only allow a single generic worker called with the same key to happen at once
      MiddleMan.new_worker( :worker => worker_type,
                            :worker_key => worker_key )
    
      MiddleMan.worker(worker_type, worker_key).async_do_work( :arg => { :method_name => method_name, :options => options } )
      true
    end
  end
end
