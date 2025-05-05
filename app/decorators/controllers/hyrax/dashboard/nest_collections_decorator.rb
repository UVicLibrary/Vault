# OVERRIDE Hyrax 4.0
# If a collection nesting relationship changes, reindex the
# child collection's nested members asynchronously. This
# ensures the Collection facet has the right count and includes
# all nested collections/works in search results.
Hyrax::Dashboard::NestCollectionsController.class_eval do

  after_action :reindex_nested_collection_members

  def reindex_nested_collection_members
    ReindexNestedMembersJob.perform_later(form_params[:child_id])
  end

end