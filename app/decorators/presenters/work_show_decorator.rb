require_dependency Hyrax::Engine.root.join('app/presenters/hyrax/work_show_presenter.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::WorkShowPresenter.class_eval do
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

  def member_presenter_factory
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter
      @member_presenter_factory ||=
          Hyrax::MemberPresenterFactory.new(solr_document, current_ability, request)
  end
end

