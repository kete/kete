class TimeoutWorker < BackgrounDRb::Worker::Base
  require 'timeout'

  def do_work(args)
    results[:timeout] = self.rescued_timeout
  end

  def simple_timeout
    Timeout::timeout(3) { sleep 5 }
  end

  def rescued_timeout
    begin
      self.simple_timeout
    rescue Timeout::Error
      "timed out"
    end
  end

end
TimeoutWorker.register
