module Hyrax
  module ControlledVocabularies
    module FastResourceLabelCaching
      CACHE_KEY_PREFIX = "hyrax_oclcfast_label-v1-"
      CACHE_EXPIRATION = 1.week

      # This is based on Hyrax::ControlledVocabularies::ResourceLabelCaching.
      # It works for fetching labels from OCLC FAST resources specifically.
      # To use this in a Hyrax::ControlledVocabularies::ClassName, include
      # it in lib/hyrax/controlled_vocabularies/class_name.rb like so:
      #
      #   include FastResourceLabelCaching

      def rdf_label
        # only cache if this rdf source is represented by a URI;
        # i.e. don't cache for blank nodes
        return super unless uri?
        # see https://apidock.com/rails/ActiveSupport/Cache/Store/fetch
        Rails.cache.fetch(cache_key) do
          (fetch && super).first
        end
      end

      ##
      # @note adds behavior to clear the cache whenever a manual fetch of data
      #   is performed.
      # @see ActiveTriples::Resource#fetch
      def fetch(*)
        Rails.cache.delete(cache_key)
        super
      end

      private

      def cache_key
        # Use the fast ID number (taken from the URI)
        "#{CACHE_KEY_PREFIX}#{to_uri.canonicalize.pname.split('/').last}"
      end

    end
  end
end