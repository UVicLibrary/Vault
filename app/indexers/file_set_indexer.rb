class FileSetIndexer < Hyrax::FileSetIndexer
  include Hyrax::IndexesLinkedMetadata
  include Hyrax::IndexesBasicMetadata
  include IndexesDownloadPermissions
  self.thumbnail_path_service = VaultThumbnailPathService

  def generate_solr_document
    object.to_controlled_vocab

    super.tap do |solr_doc|
      solr_doc['identifier_tesim'] = object.identifier

      # Transparency for images
      solr_doc['channels_tesim'] = object.characterization_proxy.alpha_channels
      solr_doc['alpha_channels_ssi'] = object.characterization_proxy.alpha_channels.first

      solr_doc['current_file_version_ssi'] = original_file_id

      solr_doc['hasFormat_ssim'] = object.rendering_ids
      # File sets should inherit the creators of their parents. Otherwise, the default "creator"
      # is indexed as the depositor instead of the work's creator.
      if object.try(:parent) && object.parent.try(:creator).present?
        parent_doc = SolrDocument.find(object.parent.id)
        solr_doc['creator_tesim'] = parent_doc['creator_tesim']
        solr_doc['creator_label_tesim'] = parent_doc['creator_label_tesim']
      end
    end
  end
  
end

