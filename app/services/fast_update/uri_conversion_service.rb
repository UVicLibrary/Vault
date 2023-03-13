module FastUpdate
  class UriConversionService < LinkedDataSearchService

    # Searches the repository for items with a specific uri (#search_for_uri) with the option
    # to limit the search to items within a particular collection, then removes or replaces it with
    # another.

    # @param [String] old uri
    # @param [Array <String>] new_uris ["http.id.worldcat.org/XXXXXX","http.id.worldcat.org/XXXXXX"]
    # @param [String] What to do with the old_uri, either ""
    # @param [Collection] optional, the collection to limit search results to
    def initialize(old_uri, new_uris, collection = nil, action:, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      @old_uri = old_uri
      @new_uris = new_uris
      @collection = collection
      @action = action
      @old_service = ActiveFedora::SolrService
      @use_valkyrie = use_valkyrie
    end

    # @param [SolrDocument or Hash] the document to be modified.
    def call(document)
      object = ActiveFedora::Base.find(document.fetch('id'))
      fields_for_conversion(document).each do |field|
        replace_or_delete_uris(object, field)
      end
      object.save!
    end

    # Search for documents that have the old uri. If results are limited to a collection,
    # this includes both Works and FileSets. Otherwise, it includes Collections, Works, and FileSets.
    # @return [Array <Hash>] results from RSolr
    def search_for_uri
      if @collection
        # If results were limited by collection, we also need to search for file sets
        # within the work that need conversion
        works = super
        file_sets = works.each_with_object([]) do |work, array|
          members = Hyrax::SolrQueryService.new.with_ids(ids: work.fetch('member_ids_ssim')).get['response']['docs']
          members.each do |document|
            if controlled_properties.any? { |field| needs_conversion?(document, field) }
              array.push(document)
            end
          end
        end
        works + file_sets
      else
        super
      end
    end

    def search_for_works
      self.superclass.send(:search_for_uri)
    end

    private

    # @param [Collection, Work, or FileSet]
    # @param [Symbol] field (e.g. :provider) to change
    def replace_or_delete_uris(object, field)
      if field.to_s == "based_near"
        class_name = "Hyrax::ControlledVocabularies::Location".constantize
      else
        class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
      end
      # Remove the old uri
      old_values = object.send(field).clone.reject { |vocab| (vocab.id == @old_uri) if (!vocab.is_a? String) }
      if @action == "replace"
        # Add the new uri(s)
        new_values = old_values + (@new_uris.map { |uri| class_name.new(uri) })
        # Set the new values on the object
        object.send("#{field}=", new_values)
      elsif @action == "delete"
        # Set the new values on the object
        object.send("#{field}=", old_values)
      else
        raise "Action not recognized. Must be replace or delete."
      end
      object.save!
    end

    # @param [Hash] document from a solr response
    # @param [Symbol] the field name for a controlled property field, e.g. :based_near
    def needs_conversion?(document, field)
      return false unless document.has_key?("#{field}_tesim")
      document.fetch("#{field}_tesim").include?(@old_uri)
    end

    # @return [Array <Symbol>] fields that need to be converted (e.g. [:creator, :provider]).
    def fields_for_conversion(document)
      controlled_properties.select { |field| needs_conversion?(document, field) }
    end

    # The query sent to Solr by #search_for_uri
    # @return [String] the joined query
    def uri_query
      @collection ? [super, collection_query].join(' AND ') : super
    end

    # @return [Array <Array>] Each nested array has 2 strings inside:
    #   1. The name for the solr field that corresponds to a controlled property (e.g. "based_near_tesim")
    #   2. @old_uri, the URI that will be changed
    # The overarching array gets passed to Hyrax::SolrQueryService
    def uri_filters
      controlled_properties.clone.map { |field_name| ["#{field_name}_#{field_suffix}", @old_uri] }
    end

    # @return [String] a query string that limits results by collection
    def collection_query
      filter_query = ['member_of_collection_ids_ssim', @collection.id]
      Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: [filter_query]).build
    end

  end
end