module BatchExport
  class AuditBatchExportJob < ActiveJob::Base

    include BatchExport::SharedMethods

    # The name of the container in OLRC
    CONTAINER_NAME = "vault"

    def perform(audit_start_date = start_date, audit_end_date = end_date)

      FileUtils.mkdir_p(Rails.root.join("log","exports"))
      log_file = Rails.root.join("log","exports", "#{audit_start_date}_to_#{audit_end_date}.log")
      failures = []

      get_recent_file_ids(audit_start_date, audit_end_date).each_with_object(failures) do |id, failures|
        file_set = FileSet.find(id)

        # We don't export images that are used solely as thumbnails for audio/video
        # works, so we don't need to audit them either.
        unless file_set.parent.nil?
          next if skip_thumbnail?(file_set)
        end

        file = "#{id}.7z"
        if (`swift list --prefix #{file} #{CONTAINER_NAME} --lh`).match?(/#{file}/)

          # Prevent writing duplicate ids to log file
          file_contents = File.read(log_file) if File.exist?(log_file)

          File.open(log_file, 'a+') do |file|
            file.puts("#{id}") if (file_contents.blank? || (file_contents.presence && file_contents.exclude?(id)))
          end

          FileUtils.rm("#{ExportFileJob::EXPORT_DIR}/#{file}") if File.exist?("#{ExportFileJob::EXPORT_DIR}/#{file}")
        else
          failures << id
        end
      end
      JobFailedMailer.mail_failures(failures: failures, job_class: self.class).deliver if failures.any?
    end

  end
end