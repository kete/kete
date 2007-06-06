require File.dirname(__FILE__) + '/../spec_helper'

describe "BackgrounDRb timeout worker" do

  before do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end

  specify "should record timed out in results" do 
    key = @middleman.new_worker :class => :timeout_worker
    worker = @middleman.worker(key)
    sleep 4
    worker.results[:timeout].should == "timed out"
  end

  specify "should raise Timeout::Error from simple_timeout" do
    require 'timeout'
    key = @middleman.new_worker :class => :timeout_worker
    worker = @middleman.worker(key)
    lambda { worker.simple_timeout }.should raise_error(Timeout::Error)
  end

  specify "should return timed out when resuced_timeout is called directly" do
    #sleep 1
    key = @middleman.new_worker :class => :timeout_worker
    worker = @middleman.worker(key)
    worker.rescued_timeout.should == "timed out"
  end

end

