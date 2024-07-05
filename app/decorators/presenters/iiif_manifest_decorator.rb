require_dependency Hyrax::Engine.root.join('app/presenters/hyrax/iiif_manifest_presenter.rb')

# OVERRIDE classes from Hyrax v. 3.1.0
Hyrax::IiifManifestPresenter.class_eval do

  def metadata_fields
    Hyrax.config.iiif_metadata_fields.is_a?(Proc) ?
        Hyrax.config.iiif_metadata_fields.call :
        Hyrax.config.iiif_metadata_fields
  end

end

Hyrax::IiifManifestPresenter::DisplayImagePresenter.class_eval do

  def solr_document
    model
  end

  def metadata_fields
    Hyrax.config.iiif_metadata_fields.is_a?(Proc) ?
        Hyrax.config.iiif_metadata_fields.call :
        Hyrax.config.iiif_metadata_fields
  end

  def display_image
    return nil unless solr_document.image?
    return nil unless latest_file_id

    IIIFManifest::DisplayImage
      .new(display_image_url(hostname),
      format: image_format(alpha_channels),
      width: width,
      height: height,
      iiif_endpoint: iiif_endpoint(latest_file_id))
  end

end