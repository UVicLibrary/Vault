class DownloadXlsxFilesWorker
  include Sidekiq::Worker

  # This exists because I can't get sidekiq-cron to enqueue ActiveJobs but it can enqueue workers properly.
  def perform
    FastUpdate::DownloadXlsxFilesJob.perform_later
  end

end
