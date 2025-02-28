# OVERRIDE Hyrax v. 4
#   - Use per-tenant metadata fields (set in config/initializers/hyrax)
#   - Fix bug where works that are not in any collections appear to be in all collections
module Hyrax::WorkShowPresenterDecorator

  delegate :visibility, :thumbnail_path, to: :solr_document

  # IIIF metadata for inclusion in the manifest
  #  Called by the `iiif_manifest` gem to add metadata
  #
  # @return [Array] array of metadata hashes
  def manifest_metadata
    metadata_fields = Hyrax.config.iiif_metadata_fields.is_a?(Proc) ?
                        Hyrax.config.iiif_metadata_fields.call :
                        Hyrax.config.iiif_metadata_fields

    metadata_fields.map do |field|
      # This line catches empty strings in the creator field [""]
      next if Array.wrap(solr_document.public_send(field)).blank?
      # Use .public_send because .send raises ArgumentError due to namespace collision
      # https://bugs.ruby-lang.org/issues/12136
      {
        'label' => "#{field.to_s.capitalize.gsub('_', ' ')}",
        'value' => Array.wrap(send(field).map { |f| Loofah.fragment(f.to_s).scrub!(:whitewash).to_s })
      }
    end.select(&:present?)
  end

  # @return [Array<String>] member_of_collection_ids with current_ability access
  def member_of_authorized_parent_collections
    return [] unless self.member_of_collection_ids.any?
    super
  end

end
Hyrax::WorkShowPresenter.prepend(Hyrax::WorkShowPresenterDecorator)


