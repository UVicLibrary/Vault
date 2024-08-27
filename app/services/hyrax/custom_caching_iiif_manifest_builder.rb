# frozen_string_literal: true
#
# New file created for Hyrax 3.4
#
# This is a drop-in replacement for Hyrax::CachingManifestBuilder
# (see app/controllers/hyrax/generic_works_controller:83).
# We want to cache manifests created by our Hyrax::CustomManifestBuilderService
# instead of the default Hyrax::ManifestBuilderService.

module Hyrax
  class CustomCachingIiifManifestBuilder < Hyrax::CachingIiifManifestBuilder

    def manifest_for(presenter:)
      # The expiry date is 30 days. To expire the cached manifest manually, run
      # Hyrax::CustomCachingIiifManifestBuilder.new.send(:manifest_cache_key, presenter: SolrDocument.find(<id>))
      # where id is the generic work ID
      Rails.cache.fetch(manifest_cache_key(presenter: presenter), expires_in: expires_in) do
        Hyrax::CustomManifestBuilderService.manifest_for(presenter: presenter)
      end
    end

    ##
    # Use timestamp for manifest key so that a new manifest gets cached if
    # a file set's content version is updated
    # @return [String]
    def version_for(presenter)
      presenter.timestamp
    end

  end
end