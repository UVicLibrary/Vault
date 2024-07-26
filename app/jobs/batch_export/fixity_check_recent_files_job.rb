module BatchExport
  class FixityCheckRecentFilesJob < BatchExport::FixityCheckJob

    # Enqueue fixity checks for works created 2-5 months ago. This job runs every 3 months.
    # You can also use this job to fixity check file sets created between any two
    # arbitrary dates.

    # @param [Date] start_date - a Solr-formatted date string like 2023-06-01T00:00:00Z
    # @param [Date] end_date - a Solr-formatted date string like 2023-08-01T00:00:Z
    def perform(start_date = five_months_ago, end_date = two_months_ago)
      # Specify the file name here to avoid creating a new log file for every file set
      log_filename = DateTime.now.strftime('%Y%m%d%H%M%S')
      
      # Equivalent to BatchExport::FixityCheckJob.perform_now(file_ids, log_filename)
      super(get_recent_file_ids(start_date, end_date), log_filename)
      # .get_recent_file_ids is defined in BatchExport::SharedMethods
    end

    def five_months_ago
      (Date.today.beginning_of_month - 5.months).midnight.strftime("%Y-%m-%d")
    end

    def two_months_ago
      (Date.today.beginning_of_month - 2.months).midnight.strftime("%Y-%m-%d")
    end

  end
end