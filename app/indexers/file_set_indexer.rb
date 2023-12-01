class FileSetIndexer < Hyrax::FileSetIndexer
  include Hyrax::IndexesLinkedMetadata
  include Hyrax::IndexesBasicMetadata
  self.thumbnail_path_service = VaultThumbnailPathService
  # Custom Vault thumbnail indexing
  include IndexesVaultThumbnails

  def generate_solr_document
    object.to_controlled_vocab

    super.tap do |solr_doc|
      solr_doc['hasFormat_ssim'] = object.rendering_ids
      # File sets should inherit the creators of their parents. Otherwise, the default "creator"
      # is indexed as the depositor instead of the work's creator.
      if object.try(:parent) && object.parent.try(:creator).present?
        parent_doc = SolrDocument.find(object.parent.id)
        solr_doc['creator_tesim'] = parent_doc['creator_tesim']
        solr_doc['creator_label_tesim'] = parent_doc['creator_label_tesim']
      end

      if object.visibility == "open" && object.try(:parent).try(:downloadable)
        solr_doc["download_access_group_ssim"] = ["public"]
      end
    end
  end
end
