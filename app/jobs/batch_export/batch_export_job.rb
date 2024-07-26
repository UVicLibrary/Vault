module BatchExport
  class BatchExportJob < ActiveJob::Base

    # Schedules ExportFileJobs for recently uploaded file sets
    # at 8 hours intervals over the weekend, and at midnight / overnight
    # on weekdays if necessary. BatchExportJobs are run on a Friday evening at 5.
    #
    # To export a bunch of files immediately instead, query for their IDs and
    # run file_ids.each { |id| ExportFileJob.perform_later(FileSet.find(id)) }

    # @param[Array <String>] - the ids of file sets to export.
    def perform(file_ids)
      # If it is Friday, Saturday, or Sunday, schedule each batch for every 8 hours
      # (Friday at 5PM; Sat at 1AM, 9AM, & 5PM; Sun at 1AM, 9AM, 5PM, 1AM)
      # If it is a weekday, schedule a batch for every day at midnight. Note that
      # the later case will be very rare since we almost never upload more than 5600
      # objects in a 3-month period.
      time = DateTime.now

      batch_ids(file_ids).each do |array|
        array.each { |id| ExportFileJob.set(wait_until: time).perform_later(FileSet.find(id)) }
        weekend?(time) ? time += 8.hours : time = (time.midnight + 1.day)
      end
    end

    # Create nested arrays of ids where each nested array
    # contains 800 ids or less, like [["id1","id2"...],["id1000","id1001"...]...]
    def batch_ids(file_ids)
      file_ids.each_slice(800).to_a
    end

    private

    def weekend?(datetime)
      ["Saturday", "Sunday"].include?(datetime.strftime("%A"))
    end

  end
end
