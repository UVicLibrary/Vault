module FastUpdate
  class ReplaceOrDeleteUriJob < ActiveJob::Base

    def perform(change_id, collection_id = nil)
      begin
        change = Change.find(change_id)
        collection = collection_id ? Collection.find(collection_id) : nil
        service = UriConversionService.new(change.old_uri, change.new_uris, collection, action: change.action)
        if service.search_for_uri.any?
          service.search_for_uri.each do |document|
            service.call(document)
            change.count += 1
          end
        end
        change.complete = true
        change.save!
      rescue StandardError
        # Change the change status so it's visible in the interface, then reraise the error
        if change.complete.nil?
          change.complete = false
          change.save!
        end
        raise
      end
    end

  end
end