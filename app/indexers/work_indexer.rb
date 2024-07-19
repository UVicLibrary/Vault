# frozen_string_literal: true

# This indexer is not used by any work type as of 8/11/2022.
# It's left here as a template for future tenant work types and
# documentation of the default thumbnail indexing options.

class WorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  include Hyrax::IndexesThumbnails

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Use thumbnails served by RIIIF
  self.thumbnail_path_service = Hyrax::WorkThumbnailPathService

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document

    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    # object.attribute_names.each do |field|
    #   if object.controlled_properties.include?(field.to_sym) and object[field].present?
    #     to_controlled_vocab(field)
    #   end
    # end

    super.tap do |solr_doc|
      # Index file sets' extracted text for display in search results
      if full_text_contents = object.ordered_members.to_a.select { |fs| fs.extracted_text.present? } and full_text_contents.present?
        solr_doc['full_text_tsi'] = full_text_contents.map {|fs| fs.extracted_text.content }.join("")
      end

      # Allow public users to discover items with institution visibility
      if object.visibility == "authenticated"
        solr_doc["discover_access_group_ssim"] = "public"
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
      val.start_with?("http") ? class_name.new(val.strip) : val
    end
  end
end