module FastUpdate
  class ModifiedHeadingsJob < ActiveJob::Base

    def perform(changes)
      changes.each do |change|
        service = service_class.new(change[:label], change[:uri])
        puts service.search_for_modified_headings
        if results = service.search_for_modified_headings
          results.each { |document| ActiveFedora::Base.find(document.id).update_index }
        end
      end
    end

    def service_class
      FastUpdate::LinkedDataSearchService
    end

  end
end