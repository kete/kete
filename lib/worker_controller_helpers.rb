# frozen_string_literal: true

# used by controllers that manage backgroundrb workers
module WorkerControllerHelpers
  unless included_modules.include? WorkerControllerHelpers

    include BackgroundrbHelpers

    # in order to prevent conflicts from other Kete installations on the same host
    # we need to add a site name prefix to our worker key
    def worker_key_for(worker_type)
      SystemSetting.site_name.gsub(/\W/, '_') + '_' + worker_type.to_s
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

    def backgroundrb_is_running?(worker_type, worker_key = nil)
      backgroundrb_running_for?(
        worker_type,
        worker_key || worker_key_for(worker_type)
      )
    end

    def delete_existing_workers_for(worker_type, worker_key = nil, with_delay = true)
      backgroundrb_delete_existing_workers_for(
        worker_type,
        worker_key || worker_key_for(worker_type)
      )
    end
  end
end
