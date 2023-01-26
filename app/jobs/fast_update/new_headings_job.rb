module FastUpdate
  class NewHeadingsJob < ActiveJob::Base

    # @param [Array <Hash>] the serialized attributes from Change objects that are the result of ParseChangesJob
    def perform(changes)
      changes.each do |change|
        service = service_class.new(change[:label], change[:uri])
        if results = service.search_for_new_headings
          results.each { |document| service.call(document) }
        end
      end
    end

    def service_class
      FastUpdate::StringConversionService
    end

  end
end