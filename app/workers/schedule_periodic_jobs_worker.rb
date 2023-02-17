class SchedulePeriodicJobsWorker
  include Sidekiq::Worker

  # Schedule fixity checks and batch export jobs for the rest of the year to run
  # on the last Friday of the month at 9 pm. This is to avoid slowing down the system
  # when uploads are running during during the day.
  #
  # Every 3 months:
  #   - run a fixity check on all works uploaded 2 months ago
  #
  # One month after that:
  #   - Get all works created in the last 3-6 months
  #   - Export to Q (staging area)
  #
  # When all files are exported, move from Q to narwhal via rails console

  WEEKDAY = :friday
  HOUR = 21 # 9:00 PM
  FIXITY_MONTHS = [2, 5, 8, 11] # The months to do fixity checks: Feb, May, Aug, Nov
  BATCH_EXPORT_MONTHS = [3, 6, 9, 12] # The months to do batch exports: Mar, June, Sept, Dec


  def perform
    year = Date.today.year
    fixity_times = calculate_times(year, FIXITY_MONTHS)
    # puts fixity_times
    fixity_times.each { |datetime| schedule_fixity(datetime) }
    batch_export_times = calculate_times(year, BATCH_EXPORT_MONTHS)
    # puts batch_export_times
    batch_export_times.each { |datetime| schedule_batch_export(datetime) }
  end

  private

  # @return [Array <DateTime>] Finds the last Fridays of the months specified and returns
  # them as an array of datetime objects
    def calculate_times(year, months)
      months.map do |month|
        datetime = DateTime.new(year, month, 1, HOUR, 0, 0, "PST")
        # If the last day of the month is a Friday, use that date
        if datetime.strftime("%A").downcase == WEEKDAY.to_s
          datetime
        else # Otherwise, find the previous Friday
          datetime.next_occurring(WEEKDAY)
        end
      end
    end

    def schedule_fixity(datetime)
      schedule_job(FixityCheckRecentWorksJob, datetime) unless datetime.past?
    end

    def schedule_batch_export(datetime)
      schedule_job(BatchExportJob, datetime) unless datetime.past?
    end

    # Enqueues a specific job on a specific date/time
    def schedule_job(job_class, date)
      job_class.set(wait_until: date).perform_later
    end
end