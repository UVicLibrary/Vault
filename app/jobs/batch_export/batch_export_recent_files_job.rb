module BatchExport
  class BatchExportRecentFilesJob < BatchExport::BatchExportJob

    include BatchExport::SharedMethods

    # This is almost the same as BatchExport::BatchExportJob except it:
    #   1. takes strings (dates in YYYY-MM-DD format) as its arguments instead
    #   2. Enqueues an audit job a week later
    def perform(start_date_string = six_months_ago, end_date_string = three_months_ago)

      super(get_recent_file_ids(start_date_string, end_date_string))

      AuditBatchExportsJob.set(wait_until: 1.week.from_now).perform_later(start_date_string, end_date_string)

    end

  end
end