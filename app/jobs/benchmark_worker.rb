class BenchmarkWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  def perform(works)
    FixityCheckJob.perform_later(works)
  end

end