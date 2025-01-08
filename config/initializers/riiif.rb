Rails.application.reloader.to_prepare do
  Riiif::Image.info_service = lambda do |id, _file|
    # id will look like a path to a pcdm:file
    # (e.g. rv042t299%2Ffiles%2F6d71677a-4f80-42f1-ae58-ed1063fd79c7)
    # but we just want the id for the FileSet it's attached to.

    # Capture everything before the first slash
    fs_id = id.gsub('%2F','/').sub(/\A([^\/]*)\/.*/, '\1')
    resp = Hyrax::SolrService.get("id:#{fs_id}")
    doc = resp['response']['docs'].first
    raise "Unable to find solr document with id:#{fs_id}" unless doc
    { height: doc['height_is'], width: doc['width_is'] }
  end

  if Hyrax.config.use_valkyrie?
    Riiif::Image.file_resolver = Hyrax::RiiifFileResolver.new
  else
    Riiif::Image.file_resolver = Riiif::HttpFileResolver.new

    Riiif::Image.file_resolver.id_to_uri = lambda do |id|
      Hyrax::Base.id_to_uri(CGI.unescape(id)).tap do |url|
        Rails.logger.info "Riiif resolved #{id} to #{url}"
      end
    end
  end

  Riiif::Image.file_resolver.basic_auth_credentials = [ActiveFedora.fedora.user, ActiveFedora.fedora.password]

  Riiif::Image.authorization_service = IIIFAuthorizationService # Hyrax::IIIFAuthorizationService

  Riiif.not_found_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')
  Riiif.unauthorized_image = Rails.root.join('app', 'assets', 'images', 'us_404.svg')

  Riiif::Engine.config.cache_duration = 1.year

  Riiif::ImagesController.class_eval do
    # Defined in the hydra-head gem
    # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
    include Hydra::Controller::IpBasedAbility
  end
end