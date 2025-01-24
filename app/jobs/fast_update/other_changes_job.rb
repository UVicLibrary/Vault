module FastUpdate
  class OtherChangesJob < ActiveJob::Base

    # Send an email with deprecated, obsolete, or split headings
    # @param [Array <Hash>] the serialized attributes from Change objects that are the result of ParseChangesJob
    def perform(changes)
      action_items = changes.each_with_object([]) do |change, array|
        service = service_class.new(change[:label], change[:uri])
        if service.search_for_uri.any?
          # TO DO: Interface option for replacing or deleting a URI. As is, you can run UriConversionService
          array << change
        end
      end
      if action_items.any?
        FastUpdate::OtherChangesMailer.with(changes: action_items).notify_user.deliver
      end
    end

    private

    def service_class
      LinkedDataSearchService
    end

  end
end