# frozen_string_literal: true

require 'methods_for_generic_muted_worker'
# meant to be a container worker
# a method name is passed in that will be run during do_work method execution
# the method must be defined within the GenericMutedWorker class
# so you need to extend the class in your code so that your method can be called from do_work
# this should limit security risks
# if you need to send arguments to your custom method, pass an options hash
# this generic work isn't expected to report back to a web ui the state of progress
# thus it is called "Muted"
class GenericMutedWorker < BackgrounDRb::MetaWorker
  set_worker_name :generic_muted_worker
  set_no_auto_load true

  include MethodsForGenericMutedWorker

  # even though this worker isn't expected to report its progress
  # provide simple debugging results hash
  def create(args = nil)
    cache[:results] = { 
      do_work_time: Time.now.utc.to_s,
      done_with_do_work: false,
      done_with_do_work_time: nil 
    }
  end

  def do_work(args = nil)
    method_name = args[:method_name]
    raise unless method_name

    if args[:options]
      send(method_name, args[:options])
    else
      send(method_name)
    end

    cache[:results] = cache[:results].merge(
      done_with_do_work: true,
      done_with_do_work_time: Time.now.utc.to_s
    )
    stop_worker
  end

  def stop_worker
    exit
  end
end
