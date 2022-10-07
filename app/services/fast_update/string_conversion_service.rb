module FastUpdate
  class StringConversionService < LinkedDataSearchService
    # Converts strings into FAST uris for all controlled property fields in a
    # given object (collection, work, file set), then saves & reindexes it.

    # @param [SolrDocument or Hash] the document to be modified. Typically a single
    # result from #search_for_new_headings.
    def call(document)
      object = ActiveFedora::Base.find(document.fetch('id'))
      fields_for_conversion(document).each do |field|
        convert_to_uris(object, field)
      end
      object.save!
    end

    # Sometimes FAST adds new headings that we have indexed in our system as string values.
    # Once the new headings are added, we need to convert those old strings/labels into uris.
    # This method searches for documents that need conversion.
    # For example, a document with
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

    private

    # @param [Hash] document from a solr response
    # @param [Symbol] the field name for a controlled property field, e.g. :based_near
    def needs_conversion?(document, field)
      label_field = label_field(field)
      return false unless document.has_key?(label_field) && document.fetch(label_field).include?(@label)
      document.fetch("#{field}_tesim").include?(@label)
    end

    # @return [Array <Symbol>] fields that need to be converted (e.g. [:creator, :provider]).
    def fields_for_conversion(document)
      controlled_properties.select { |field| needs_conversion?(document, field) }
    end

    # @param [Collection, Work, or FileSet]
    # @param [Symbol] field (e.g. :provider) to change
    def convert_to_uris(object, field)
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
      new_values = object.send(field).clone.map do |value|
        value == @label ? class_name.new(@uri) : value
      end
      object.send("#{field}=", new_values)
    end

  end
end