class WorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Use thumbnails served by RIIIF
  self.thumbnail_path_service = IIIFWorkThumbnailPathService

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document

    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.attribute_names.each do |field|
      if object.controlled_properties.include?(field.to_sym) and object[field].present?
        to_controlled_vocab(field)
      end
    end

    super.tap do |solr_doc|

      if object.thumbnail and object.thumbnail.files.any?
        if object.thumbnail.audio? or object.thumbnail.files.first.file_name.first.include?(".m4a")
          solr_doc['thumbnail_path_ss'] = AudioFileSetThumbnailService.call(object.thumbnail)
        end
      end

      # Index OAI-PMH fields

      # dc:coverage = geographic coverage + chronological coverage
      if solr_doc['geographic_coverage_label_tesim'] or solr_doc['chronological_coverage_tesim']
        geographic_label = solr_doc['geographic_coverage_label_tesim']
        chronological_label = solr_doc['chronological_coverage_tesim']
        solr_doc['oai_dc_coverage_tesim'] = [geographic_label, chronological_label].reject { |val| val.nil? }.flatten
      end
      # dc:resource_type = human readable label for resource type (e.g. StillImage)
      if resource_type = solr_doc['resource_type_tesim']
        solr_doc['oai_dc_type_tesim'] = resource_type.map { |val| Hyrax::ResourceTypesService.label(val).gsub(' ','') }
      end
      # dc:relation = title of parent collection if one exists
      if collections = solr_doc['member_of_collections_ssim']
        solr_doc['oai_dc_relation_tesim'] = collections.map { |val| "IsPartOf #{val}" }
      end

      # Vault considers m4a files to be videos even if they only have an audio track.
      # This sets the thumbnail path back to the audio thumbnail.
      if object.thumbnail and object.thumbnail.video? and object.thumbnail.label.include?(".m4a")
        solr_doc['thumbnail_path_ss'] = AudioFileSetThumbnailService.call(object.thumbnail)
      end

      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?

      # Index file sets' extracted text for display in search results
      if full_text_contents = object.file_sets.select { |fs| fs.extracted_text.present? } and full_text_contents.present?
        solr_doc['full_text_tsi'] = full_text_contents.map {|fs| fs.extracted_text.content }.join("")
      end

      # Allow public users to discover items with institution visibility
      if object.visibility == "authenticated"
        solr_doc["discover_access_group_ssim"] = "public"
      end

      unless object.date_created.empty?
        object.date_created.each do |date|
          service = EdtfDateService.new(date)
          # Email for unparseable dates
          if service.first_solr_date.blank? and (date != "unknown" and date != "no date")
            ::NotificationMailer.with(user_email: "tjychan@uvic.ca", failures: [object.id]).failures.deliver
          end
          # Unparseable dates will return nil so nothing gets indexed here
          solr_doc['year_sort_dtsim'] = service.solr_date_range
          solr_doc['year_sort_dtsi'] = service.first_solr_date
          solr_doc['year_range_isim'] = service.year_range
        end
      end

    end
  end

  private

  # field is a symbol/controlled property
  # returns an array of Hyrax::ControlledVocabularies::[field]
  def to_controlled_vocab(field)
    if field.to_s == "based_near"
      class_name = "Hyrax::ControlledVocabularies::Location".constantize
    else
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
    end
    object[field] =  object[field].map do |val|
      val.include?("http") ? class_name.new(val.strip) : val
    end
  end
end