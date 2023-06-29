# frozen_string_literal: true
require 'bolognese'

module Bolognese
  module Readers
    module VaultWorkReader
      include Bolognese::Readers::HyraxWorkReader

      # Use this with Bolognese like the following:
      # m = Bolognese::Metadata.new(input: work.attributes.merge(has_model: work.has_model.first).to_json, from: 'generic_work')
      # Call m.datacite to see the XML that is submitted to DataCite
      def read_generic_work(string: nil, **options)
        read_options = ActiveSupport::HashWithIndifferentAccess.new(options.except(:doi, :id, :url, :sandbox, :validate, :ra))

        # Construct a hash of work attributes
        attrs = string.present? ? Maremma.from_json(string) : {}

        metadata = {
            "identifiers" => read_hyrax_work_identifiers(attrs),
            "types" => read_hyrax_work_types(attrs),
            "doi" => draft_or_existing_doi(attrs, options[:doi]),
            "titles" => read_hyrax_work_titles(attrs),
            "creators" => read_hyrax_work_creators(attrs),
            "contributors" => read_hyrax_work_contributors(attrs),
            "publisher" => read_hyrax_work_publisher(attrs),
            # "related_identifiers" => related_identifiers,
            # "dates" => dates,
            "publication_year" => read_hyrax_work_publication_year(attrs),
            "descriptions" => read_hyrax_work_descriptions(attrs),
            # "rights_list" => rights_list,
            # "version_info" => attrs.fetch("version", nil),
            "subjects" => read_hyrax_work_subjects(attrs)
            # "state" => state
        # Only submit fields that have non-blank values (exclude empty strings like [""])
        }.select { |_, value| value.present? && (value.is_a?(Array) ? value.all?(&:present?) : true) }
        metadata.merge(read_options)
      end

      def draft_or_existing_doi(attrs, draft_doi)
        doi = attrs.fetch('doi', nil)&.first || draft_doi
        normalize_doi(doi)
      end

      def read_hyrax_work_contributors(attrs)
        get_authors(Array.wrap(meta.fetch("contributor", nil))) if attrs.fetch("contributor", nil).any?(:present?)
      end

    end
  end
end

