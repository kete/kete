class ResultsParallelWorker < BackgrounDRb::Worker::Base
  def do_work(args)
    args.times do |counter|
      results[:data] = Time.now
      results[:counter] = counter
    end
  end
end
ResultsParallelWorker.register
