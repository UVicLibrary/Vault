module FastUpdate
  class ParseChangesJob < ActiveJob::Base

    # @param [Array <String>] the pathnames of the .xlsx files to parse
    def perform(filepaths)
      filepaths.each do |filepath|
        changes = parser_class.new(filepath).parse_data

        new_headings = changes.select { |c| c.type == "New Heading" }
        mod_headings = changes.select { |c| c.type == "Modified Heading" }
        other_changes = changes.select { |c| c.type != "Modified Heading" && c.type != "New Heading" }

        # Convert change objects to hashes before calling the jobs
        # https://github.com/mperham/sidekiq/wiki/Best-Practices#1-make-your-job-parameters-small-and-simple
        NewHeadingsJob.perform_later(new_headings.map(&:attributes)) if new_headings.any?
        ModifiedHeadingsJob.perform_later(mod_headings.map(&:attributes)) if mod_headings.any?
        OtherChangesJob.perform_later(other_changes.map(&:attributes)) if other_changes.any?
      end
    end

    private

    def parser_class
      FastUpdate::XlsxParser
    end
  end
end