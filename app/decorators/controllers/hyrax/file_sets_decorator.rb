require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/file_sets_controller.rb')

# OVERRIDE class from Hyrax v. 3.5
Hyrax::FileSetsController.class_eval do

  # Defined in the hydra-head gem
  # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
  include Hydra::Controller::IpBasedAbility

  after_action :expire_parent_manifest_cache, only: [:update]

  def show_presenter
    # Tenant-specific file set presenters
    if multitenant?
      if current_account.cname.include? "vault"
        VaultFileSetPresenter
      elsif current_account.cname.include? "iaff"
        Hyrax::FileSetPresenter
      end
    else
      VaultFileSetPresenter
    end
  end

  def edit
    initialize_edit_form
    @parent = presenter.parent
  end

  # Expire the parent work's cached IIIF manifest so that the updated
  # file set metadata shows up in Universal Viewer
  def expire_parent_manifest_cache
    return if presenter.parent.nil?
    # We only need an object that responds to :id and :timestamp, so a solr doc will suffice
    doc = SolrDocument.find(presenter.parent.id)
    cache_key = Hyrax::CustomCachingIiifManifestBuilder.new.send(:manifest_cache_key, presenter: doc)
    Rails.cache.delete(cache_key)
  end

end