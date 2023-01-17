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

    private

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