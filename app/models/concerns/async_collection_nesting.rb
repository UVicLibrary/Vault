# frozen_string_literal: true
module AsyncCollectionNesting

  # If it is a full reindex, turn this expensive and
  # potentially lengthy process into a background job
  # instead of running in the foreground
  def reindex_nested_relationships_for(id:, extent:)
    case extent
    when "full"
      ReindexNestedRelationshipsJob.perform_later(id)
    else
      super
    end
  end

end