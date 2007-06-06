$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/../server/lib')

require 'rubygems'
require 'spec'
require 'drb'
require 'singleton'

root = File.expand_path(File.dirname(__FILE__) + '/data/server')

BACKGROUNDRB_ROOT = root unless defined?(BACKGROUNDRB_ROOT)
BACKGROUNDRB_CODE = Dir.pwd unless defined?(BACKGROUNDRB_CODE)
BACKGROUNDRB_STANDALONE = true unless defined?(BACKGROUNDRB_STANDALONE)
require 'backgroundrb_server'

class SpecBackgrounDRbServer
  include Singleton
  attr_accessor :started

  def setup
    @context_counter ||= 1
    ARGV[0] = "start"
    ARGV[1] = "--"
    ARGV[2] = "-w"
    ARGV[3] = BACKGROUNDRB_ROOT + "/workers"
    ARGV[4] = "-t"
    ARGV[5] = "/tmp/spec_tmp" + @context_counter.to_s
    ARGV[6] = "-p"
    ARGV[7] = "2727"
    ARGV[8] = "-P"
    ARGV[9] = "druby"
    @server = BackgrounDRb::Server.new.run
    @started = true
    sleep 2
  end

  def shutdown
    ARGV[0] = "stop"
    ARGV[1] = "--"
    ARGV[2] = "-w"
    ARGV[3] = BACKGROUNDRB_ROOT + "/workers"
    ARGV[4] = "-t"
    ARGV[5] = "/tmp/spec_tmp" + @context_counter.to_s
    ARGV[6] = "-p"
    ARGV[7] = "2727"
    ARGV[8] = "-P"
    ARGV[9] = "druby"
    BackgrounDRb::Server.new.run
    @started = false
    @context_counter += 1
    sleep 2
  end

end

def spec_run_setup
  unless SpecBackgrounDRbServer.instance.started
    SpecBackgrounDRbServer.instance.setup
  end
  DRbObject.new(nil, "druby://localhost:2727")
end

def spec_run_teardown
end
