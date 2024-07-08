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

end