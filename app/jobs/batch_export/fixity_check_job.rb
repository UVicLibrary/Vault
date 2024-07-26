module BatchExport
  class FixityCheckJob < ActiveJob::Base

    include BatchExport::SharedMethods

    # Note that FileSets must be checked sequentially (one-by-one) due to a bug
    # in Fedora 4 that causes checks to "fail" whenever more than one is run at once.
    # This bug will be fixed in Fedora 6.

    # @param [Array <String>] - the IDs of file sets to fixity check
    def perform(file_set_ids, log_filename = DateTime.now.strftime('%Y%m%d%H%M%S') )
      File.open("/usr/local/rails/vault/log/fixity/#{log_filename}.log", 'w') do |log_file|
        failed_ids = file_set_ids.each_with_object([]) do |id, array|
          puts "Checking #{id}"
          file_set = FileSet.find(id)
          # If file set has no parent, we can't save it
          (file_set.destroy! && next) if file_set.parent.nil?
          # No need to check a file set if it passed a fixity check within the last month or
          # is just a thumbnail for a work with an audio/video representative.
          next if passed_recent_check?(file_set) or skip_thumbnail?(file_set)
          begin
            fixity = ActiveFedora::FixityService.new file_set.latest_content_version.uri
          rescue NoMethodError => error
            log_file.write "#{file_set.id} has no files attached"
            array << file_set
            next
          end
          unless fixity.check
            log_file.write("#{file_set.id} has a possible corruption")
            array << file_set
          end
          file_set.last_fixity_check = log_filename
          file_set.save!
        end
        log_file.write("Finished Fixity Checking")
        JobFailedMailer.fixity_failures(file_sets: failed_ids, job_class: self.class).deliver if failed_ids.any?
      end
    end

    private

    def passed_recent_check?(file_set)
      return false unless file_set.last_fixity_check.present?
      last_check_date = DateTime.parse(file_set.last_fixity_check)
      (1.month.ago..Time.now).cover?(last_check_date) && passed?(file_set)
    end

    def passed?(file_set)
      log_path = "/usr/local/rails/vault/log/fixity/#{file_set.last_fixity_check}.log"
      return false unless File.file? log_path
      File.read(log_path).exclude?(file_set.id)
    end

  end
end