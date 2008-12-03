module ServerControls
  class SeleniumServerControls
    cattr_accessor :pid_file, :start_command

    # move the actual staring and stopping of the Selenium process to a rake task
    # to resolve stop issues (both servers have the same parent group id)

    def start
      begin
        #stop if running?
        pid = Process.fork do
          system(start_command)
        end
        raise if pid.nil?
        pid = pid + 2  # I don't know why, but between asking the server to start and it happening, two other processes execute
                       # So for now, I'll just bump the version number here by 2 to fix that
        op = File.open(pid_file, "w")
        op.write(pid.to_s)
        op.close
        sleep 10 # give the testing server time to start up
      rescue
        raise "ERROR: Could not start service with the following commands.
               #{start_command}"
      end
    end

    def stop
      begin
        pid = nil
        pid = File.open(pid_file, "r") { |pid_handle| pid_handle.gets.strip.chomp.to_i }
        puts "Killing #{pid}"
        pgid = Process.getpgid(pid)
        Process.kill('-TERM', pgid)
        File.delete(pid_file) if File.exists?(pid_file)
        puts "Killed #{pid} by way of #{pgid}"
        sleep 2 # give it time to shutdown any finishing requests
      rescue
        raise "ERROR: Could not stop server with pid of #{pid} and pgid of #{pgid}.
               Please kill it manually and try again."
      end
    end

    def restart
      stop
      start
    end

    def running?
      File.exists?(pid_file)
    end
  end

  class SeleniumRCServer < SeleniumServerControls
    def initialize pid_file
      command = "java -jar #{SELENIUM_SERVER_JARFILE}"
      command << " -port #{SELENIUM_SERVER_PORT}"
      command << " -timeout #{SELENIUM_SERVER_TIMEOUT}"
      command << " -log #{Rails.root}/log/selenium_rc_server.log"
      command << " &" # this makes the process run in the background
      self.start_command = command
      self.pid_file = pid_file
    end
  end

  class SeleniumWebServer < SeleniumServerControls
    def initialize pid_file
      command = "#{Rails.root}/script/server"
      command << " -p #{SELENIUM_WEB_SERVER_PORT}"
      command << " -e test"
      command << " >#{Rails.root}/log/selenium_web_server.log"
      command << " &" # this makes the process run in the background
      self.start_command = command
      self.pid_file = pid_file
    end
  end
end