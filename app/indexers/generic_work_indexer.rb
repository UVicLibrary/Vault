class GenericWorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata
  # Custom Vault thumbnail indexing
  include IndexesVaultThumbnails

  # For ingest into main UVic library catalog
  include IndexesOAIFields

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  self.thumbnail_path_service = VaultThumbnailPathService

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document

    # app/models/concerns/vault_basic_metadata
    object.to_controlled_vocab

    super.tap do |solr_doc|
      # Index title sort field since we can't sort on a _tesim field
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?

      # Index file sets' extracted text for display in search results
      if full_text_contents = object.file_sets.select { |fs| fs.extracted_text.present? } and full_text_contents.present?
        solr_doc['full_text_tsi'] = full_text_contents.map {|fs| fs.extracted_text.content }.join("")
      end

      solr_doc['identifier_tesim'] = object.identifier
      solr_doc['related_url_tesim'] = object.related_url

      # Allow public users to discover items with institution visibility
      if object.visibility == "authenticated"
        solr_doc["discover_access_group_ssim"] = "public"
      end

      # Index public users into a download group. TO DO: remove the downloadable
      # attribute entirely and manage download access with CanCan & Blacklight
      # access controls gem
      if object.visibility == "open" && object.downloadable
        solr_doc["download_access_group_ssim"] = ["public"]
      end

      unless object.date_created.empty?
        object.date_created.each do |date|
          service = EdtfDateService.new(date)
          (solr_doc['year_sort_dtsim']||= []) << service.solr_date_range
          (solr_doc['year_range_isim']||=[]) << service.year_range
        end
        solr_doc['year_sort_dtsim'] = solr_doc['year_sort_dtsim'].flatten.uniq.sort
        solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
        solr_doc['year_range_isim'] = solr_doc['year_range_isim'].flatten.uniq.sort
      end

    end
  end
end