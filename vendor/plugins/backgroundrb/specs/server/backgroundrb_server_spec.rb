#$DEBUG = true
require File.dirname(__FILE__) + '/../spec_helper'

describe "BackgrounDRb simple worker" do

  before(:all) do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end
  
  before do
    @key = @middleman.new_worker :class => :simple_worker
    @worker = @middleman.worker(@key)
  end
  
  after do
    @worker.delete
  end

  specify "should return string from method" do
    @worker.simple_work.should == "simple string returned from worker"
  end

  specify "should set result in method call" do
    @worker.simple_result
    @worker.results[:simple].should == "simple result string"
  end

  specify "should allow for result to be set externally" do
    # set results from outside the worker
    @worker.results[:external] = 9
    @worker.results[:external].should == 9

    results_hash = @worker.results.to_hash
    results_hash[:external].should == 9
  end

  specify "should keep results after worker is deleted" do
    @worker.simple_result
    @worker.results[:external] = 9
  
    spec_hash = {
      :simple => "simple result string",
      :external => 9
    }

    results_hash = @worker.results.to_hash
    results_hash.should == spec_hash
    @worker.delete

    # results should still be available after the worker is deleted
    @worker.results.to_hash.should == spec_hash
  end

  # When the server was started each time setup was called, every other
  # invocation resulted in an IOError in the WorkerProxy, Moving the
  # server into a singleton class where there is only a single server
  # per context, resolved this issue.
  4.times do
    specify "should work on on subsequent server invocations" do
      @worker.simple_work.should == "simple string returned from worker"
      lambda { @worker.delete }.should_not raise_error(IOError)
    end
  end

end

describe "BackgrounDRb simple worker scheduler" do

  before(:all) do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end

  specify "should schedule with simple trigger" do 

    @middleman.schedule_worker(
      :class => :simple_worker,
      :job_key => :scheduled_worker,
      :worker_method => :simple_work_with_logging,
      :trigger_args => {
        :start => Time.now+1, 
        :end => Time.now+3,
        :repeat_interval => 1
      }
    )

    @middleman.scheduler.jobs.should_not be_empty
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_not be_empty
    sleep 5
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should be_empty

  end

  specify "should call do_work with args" do

    @middleman.schedule_worker(
      :class => :do_work_with_arg_worker,
      :args => "args for args",
      :job_key => :with_arg_worker,
      :trigger_args => {
        :start => Time.now+1, 
        :end => Time.now+3,
        :repeat_interval => 1
      }
    )
    sleep 2
    results = @middleman.worker(:with_arg_worker).results
    results[:from_do_work].should == "args for args"
    sleep 2
    @middleman.scheduler.clean_up
  end

  specify "should schedule with simple trigger on existing worker" do 
    @middleman.new_worker :class => :simple_worker, 
      :job_key => :scheduled_worker

    @middleman.schedule_worker(:job_key => :scheduled_worker,
      :worker_method => :simple_work_with_logging,
      :trigger_type => :trigger,
      :trigger_args => {:start => Time.now+1, 
        :repeat_interval => 1, :end => Time.now+3})

    @middleman.scheduler.jobs.should_not be_empty
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should_not be_empty
    sleep 4
    @middleman.scheduler.clean_up
    @middleman.scheduler.jobs.should be_empty
  end

  specify "should schedule with MiddleMan#schedule_worker" do
    @middleman.new_worker :class => :simple_worker, 
      :job_key => :scheduled_worker

    @middleman.schedule_worker(:job_key => :scheduled_worker,
      :worker_method => :do_something,
      :worker_method_args => "my argument",
      :trigger_type => :cron_trigger,
      :trigger_args => '0 15 10 * * * *')

    # do something better here, since objects scheduler.jobs contains
    # Proc objects, DRb will fall back to the main DRbObject.
    @middleman.scheduler.jobs.should_not be_empty
  end

  specify "should create worker if it's not already created" do

    @middleman.schedule_worker(:job_key => :new_worker,
      :class => :simple_worker, :trigger_args => '0 15 10 * * * *' )

  end

  specify "should schedule with :schedule_worker option to #new_worker" do
  end

end

describe "BackgrounDRb worker logging" do

  before(:all) do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end

  specify "should use method instead of instance variable" do

    key = @middleman.new_worker :class => :simple_worker, 
      :job_key => :yikes
    worker = @middleman.worker(key)
    worker.logger.info "logging something new"
    # TODO: make an expectation
  end

end

describe "BackgrounDRb worker classes" do

  before(:all) do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end

  specify "should be registered" do

    @middleman.new_worker :class => :simple_worker, 
      :job_key => :yikes
    @middleman.loaded_worker_classes.sort.should == ["DoWorkWithArgWorker","RSSWorker", "ResultsParallelWorker", "SimpleWorker","TimeoutWorker"].sort
  end

end

describe "BackgroundDRb results worker" do
  setup do
    @middleman = spec_run_setup
  end

  after(:all) do
    SpecBackgrounDRbServer.instance.shutdown
  end

  specify "multiple results" do

    iterations = 99
    job_keys = [ :first, :second, :third, :fourth, :fifth, :sixth, :seventh, :eight ]

    job_keys.each do |job_key|
      @middleman.new_worker :class => :results_parallel_worker, :job_key => job_key, :args => iterations
    end

    all_done = false

    until all_done
      completed = 0
      job_keys.each do |job_key|
        worker = @middleman.worker(job_key)
        counter = worker.results[:counter]
        if counter == iterations - 1
          completed += 1
        end
        puts "#{job_key}: #{counter}"
        sleep 1
      end
      all_done = true if completed == job_keys.length
    end

  end

end
