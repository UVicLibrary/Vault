class ReindexNestedRelationshipsJob < ActiveJob::Base

  def perform(id)
    Hyrax.config.nested_relationship_reindexer.call(id: id, extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX)
  end

end