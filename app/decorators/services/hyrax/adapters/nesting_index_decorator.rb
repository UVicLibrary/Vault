# frozen_string_literal: true
require_dependency Hyrax::Engine.root.join('app/services/hyrax/adapters/nesting_index_adapter.rb')

# Changed to use the (legacy) standard parser to maintain
# compatibility with Solr versions >= 9.

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::Adapters::NestingIndexAdapter.module_eval do

  # Avoid ActiveFedora::SolrQueryBuilder
  # @api private
  def self.find_solr_document_by(id:)
    # query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
    query = Hyrax::SolrQueryService.new.with_ids(ids: [id]).build
    document = Hyrax::SolrService.query(query, rows: 1).first
    document = ActiveFedora::Base.find(id).to_solr if document.nil?
    raise "Unable to find SolrDocument with ID=#{id}" if document.nil?
    document
  end
  private_class_method :find_solr_document_by

  # @api private
  # @param parent_document [Curate::Indexer::Documents::IndexDocument]
  # @return [Hash] A raw response document from SOLR
  # @todo What is the appropriate suffix to apply to the solr_field_name?
  def self.raw_child_solr_documents_of(parent_document:)
    # query Solr for all of the documents included as a member_of_collection parent. Or up to 10000 of them.
    child_query = Hyrax::SolrQueryService.new.with_field_pairs(field_pairs: [["member_of_collection_ids_ssim", parent_document.id]]).build
    # Limit the Solr query to only the fields we need to reindex parent/child relationships
    field_list = [solr_field_name_for_storing_pathnames,
                  solr_field_name_for_storing_ancestors,
                  solr_field_name_for_storing_parent_ids, "id"].join(",")
    Hyrax::SolrService.query(child_query, rows: 10_000.to_i, fl: field_list)
  end
  private_class_method :raw_child_solr_documents_of

end

