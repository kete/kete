require File.join(File.dirname(__FILE__) + "/bdrb_test_helper")
require "meta_worker"

context "A Meta Worker should" do
  setup do
    BackgrounDRb::MetaWorker.worker_name = "hello_worker"
    class BackgrounDRb::MetaWorker
      attr_accessor :outgoing_data
      attr_accessor :incoming_data
      def send_data(data)
        @outgoing_data = data
      end

      def start_reactor; end
    end
    meta_worker = BackgrounDRb::MetaWorker.start_worker
  end

  specify "load appropriate db environment from config file" do
    ActiveRecord::Base.connection.current_database.should == "rails_sandbox_production"
  end

  xspecify "load appropriate schedule from config file" do

  end

  xspecify "run a task if on schedule" do

  end

  xspecify "register status request should be send out to master" do

  end
end

