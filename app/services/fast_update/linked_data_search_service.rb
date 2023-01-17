module FastUpdate
  class LinkedDataSearchService < Hyrax::SolrService
    # Searches Solr for documents that contain a specific uri or human-readable label
    # in all controlled property fields
    # This is a parent class for StringConversionService and UriConversionService

    def initialize(label, uri, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      @label = label
      @uri = uri
      @old_service = ActiveFedora::SolrService
      @use_valkyrie = use_valkyrie
    end

    # Sometimes FAST changes the human-readable label for a uri, so we need to search for
    # documents that need to be reindexed (i.e. documents where we need to replace the
    # old label with the new one.)
    # @return [Array<Hash>] the response documents
    def search_for_modified_headings
      search_for_uri.select do |document|
        controlled_properties.any? { |field| has_old_label?(document, field) }
      end
    end

    # Sometimes FAST adds new headings that we have indexed in our system as string values.
    # Once the new headings are added, we need to convert those old strings/labels into uris.
    # This method searches for documents that need conversion, for example, a document with
    # { "creator_tesim" => ["Tiffany and Company"],
    #       "creator_label_tesim" => ["Tiffany and Company"] }
    # instead of
    # { "creator_tesim" => ["http://id.worldcat.org/fast/549011"],
    #       "creator_label_tesim" => ["Tiffany and Company"] }
    # @return [Array<Hash>] the response documents
    def search_for_new_headings
      search_for_label.select do |document|
        controlled_properties.any? { |field| needs_conversion?(document, field) }
      end
    end

    # Search solr for documents with a specific human-readable label
    # @return [Array<Hash>] the response documents
    def search_for_label
      # We sort because we want GenericWorks before FileSets since file sets inherit the creator
      # of their parent. If we change file sets before works, the file set's creator will be overwritten
      # by the work's creator. (This is custom behavior, not Hyrax.)
      connection.get(label_query, rows: rows, sort: sort_field)['response']['docs']
    end

    # Search solr for documents with a specific uri
    # @return [Array<Hash>] the response documents
    def search_for_uri
      # We sort because we want GenericWorks before FileSets since file sets inherit the creator
      # of their parent. If we change file sets before works, the file set's creator will be overwritten
      # by the work's creator. (This is custom behavior, not Hyrax.)
      connection.get(uri_query, rows: rows, sort: sort_field)['response']['docs']
    end

    protected

    # @param [Hash] document from a solr response
    # @param [Symbol] the field name for a controlled property field, e.g. :based_near
    def has_old_label?(document, field)
      uri_field = "#{field}_tesim"
      return false unless document.has_key?(uri_field) && document.fetch(uri_field).include?(@uri)
      document.fetch(label_field(field)) != @label
    end

    # @param [Hash] document from a solr response
    # @param [Symbol] the field name for a controlled property field, e.g. :based_near
    def needs_conversion?(document, field)
      label_field = label_field(field)
      return false unless document.has_key?(label_field) && document.fetch(label_field).include?(@label)
      document.fetch("#{field}_tesim").include?(@label)
    end

    # @return [Array <Array>] Each nested array has 2 strings inside:
    #   1. The name for the corresponding label field (e.g. "based_near_label_tesim")
    #   2. @label, the most recent human-readable label/string specified by the FAST change
    # The overarching array gets passed to Hyrax::SolrQueryService
    def label_filters
      controlled_properties.clone.map { |field_name| ["#{field_name}_label_#{field_suffix}", @label] }
    end

    # @return [Array <Array>] Each nested array has 2 strings inside:
    #   1. The name for the solr field that corresponds to a controlled property (e.g. "based_near_tesim")
    #   2. @uri, the most recent uri specified by the FAST change
    # The overarching array gets passed to Hyrax::SolrQueryService
    def uri_filters
      controlled_properties.clone.map { |field_name| ["#{field_name}_#{field_suffix}", @uri] }
    end

    # @param [Symbol or String] field name like :creator or "creator"
    def label_field(field)
      "#{field}_label_#{field_suffix}"
    end

    # @return [String] a joined query for searching label fields
    def label_query
      Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: label_filters,
                                                   join_with: join_with).build
    end

    # @return [String] a joined query for searching controlled property fields
    def uri_query
      Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: uri_filters,
                                                   join_with: join_with).build
    end

    def join_with
      " OR "
    end

    def field_suffix
      "tesim"
    end

    def rows
      12000
    end

    def sort_field
      'has_model_ssim desc'
    end

    def controlled_properties
      # For all work types:
      # Hyrax.config.curation_concerns.map(&:constantize).map(&:controlled_properties).flatten.uniq
      Hyrax.primary_work_type.controlled_properties
    end

    #
    # @api private
    def connection
      return @old_service unless use_valkyrie
      valkyrie_index.connection
    end
  end
end