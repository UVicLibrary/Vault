require_dependency Hyrax::Engine.root.join('app/indexers/hyrax/deep_indexing_service.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::DeepIndexingService.class_eval do

  # Appends the uri to the default solr field and puts the label (if found) in the label solr field
  # @param [Hash] solr_doc
  # @param [String] solr_field_key
  # @param [Hash] field_info
  # @param [Array] val an array of two elements, first is a string (the uri) and the second is a hash with one key: `:label`
  def append_label_and_uri(solr_doc, solr_field_key, field_info, val)
    val = val.solrize
    ActiveFedora::Indexing::Inserter.create_and_insert_terms(solr_field_key,
                                                            val.first,
                                                            field_info.behaviors, solr_doc)
    return unless val.last.is_a? Hash
    ActiveFedora::Indexing::Inserter.create_and_insert_terms("#{solr_field_key}_label",
                                                            label(val),
                                                            field_info.behaviors, solr_doc)
  end

  # This prevents a "No method solrize for ActiveTriples::Resource" error
  # Return a tuple of uri & label
  def solrize(val)
    val.instance_of?(ActiveTriples::Resource) ? [val.id, { label: "#{val.rdf_label.first}$#{val.id}" }] : val.solrize
  end
end
