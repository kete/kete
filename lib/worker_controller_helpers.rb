# used by controllers that manage backgroundrb workers
module WorkerControllerHelpers
  unless included_modules.include? Importer
    def backgroundrb_is_running?(worker_type)
      is_running = false
      MiddleMan.all_worker_info.each do |server|
        if !server[1].nil?
          server[1].each { |workers| is_running = true if @worker_type == workers[:worker] }
        end
        break if is_running
      end
      is_running
    end
  end
end
