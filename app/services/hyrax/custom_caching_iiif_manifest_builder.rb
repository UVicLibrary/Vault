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
      # Rails.cache.delete(manifest_cache_key(presenter: presenter))
      Rails.cache.fetch(manifest_cache_key(presenter: presenter), expires_in: expires_in) do
        Hyrax::CustomManifestBuilderService.manifest_for(presenter: presenter)
      end
    end

  end
end