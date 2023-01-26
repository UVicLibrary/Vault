module FastUpdate
  class ParseChangesJob < ActiveJob::Base

    # @param [String] the filepath to the .xlsx file you want to parse
    def perform(filepath)
      changes = FastUpdate::XlsxParser.new(filepath).parse_data

      new_headings = changes.select { |c| c.type == "New Heading" }
      mod_headings = changes.select { |c| c.type == "Modified Heading" }
      other_changes = changes.select { |c| c.type != "Modified Heading" && c.type != "New Heading" }

      # Convert change objects to hashes before calling the jobs
      # https://github.com/mperham/sidekiq/wiki/Best-Practices#1-make-your-job-parameters-small-and-simple
      NewHeadingsJob.perform_later(new_headings.map(&:attributes))
      ModifiedHeadingsJob.perform_later(mod_headings.map(&:attributes))
      OtherChangesJob.perform_later(other_changes.map(&:attributes))
    end

  end
end