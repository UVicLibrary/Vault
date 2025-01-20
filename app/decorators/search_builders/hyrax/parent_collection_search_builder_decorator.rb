# OVERRIDE Hyrax 4.0 to use Hyrax::SolrQueryService instead of
# the deprecated Hyrax::SolrQueryBuilderService
Hyrax::ParentCollectionSearchBuilder.class_eval do

  # include filters into the query to only include the collections containing this item
  def include_item_ids(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [Hyrax::SolrQueryService.new.with_ids(ids: item.member_of_collection_ids).build]
  end

end