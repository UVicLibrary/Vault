# frozen_string_literal: true
require 'bolognese/metadata'

module Bolognese
  module Readers
    module GenericWorkReader
      include Bolognese::Readers::HyraxWorkReader

      # Mapping from our resource type controlled vocabulary to the list of controlled values
      # allowed in resourceTypeGeneral attribute of <resourceType/>. Note: this list is not
      # complete, but we've tried to cover the most common types for Vault resources. See
      # https://support.datacite.org/docs/datacite-metadata-schema-v44-mandatory-properties#10-resourcetype
      GENERAL_TYPES = {
        "Moving Image" => "Audiovisual",
        "Collection" => "Collection",
        "Still Image" => "Image",
        "Image" => "Image",
        "Physical Object" => "PhysicalObject",
        "Sound" => "Sound",
        "Text" => "Text"
      }

      def read_generic_work(string: nil, **options)
        read_options = ActiveSupport::HashWithIndifferentAccess.new(options.except(:doi, :id, :url, :sandbox, :validate, :ra))

        # Construct a hash of work attributes
        attrs = string.present? ? Maremma.from_json(string) : {}

        puts "#{attrs.fetch('id')}"

        metadata = {

            # MANDATORY FIELDS
            # Use the work ID as an alternate identifier
            "identifiers" => read_hyrax_work_identifiers(attrs),
            "doi" => draft_or_existing_doi(attrs, options[:doi]),
            "titles" => read_hyrax_work_titles(attrs),
            "creators" => read_hyrax_work_creators(attrs),
            # In Vault, we define publisher as the publisher of the original material.
            # But in this context, "publisher" should be the publisher of the digital work
            "publisher" => "University of Victoria Libraries",
            "publication_year" => read_hyrax_work_create_date(attrs),
            "types" => read_hyrax_work_resource_types(attrs),

            # RECOMMENDED FIELDS
            "contributors" => read_hyrax_work_contributors(attrs),
            "descriptions" => read_hyrax_work_descriptions(attrs),
            "subjects" => read_hyrax_work_subjects(attrs),
            "geo_locations" => read_hyrax_work_geo_locations(attrs),
            "dates" => read_hyrax_work_dates(attrs),

            # OPTIONAL FIELDS
            "rights_list" => read_hyrax_work_rights_list(attrs),
            "formats" => read_hyrax_work_formats(attrs),
            "language" => read_hyrax_work_languages(attrs)

            # Only submit fields that have non-blank values (exclude empty strings like [""])
        }.select { |_, value| value.present? && (value.is_a?(Array) ? value.all?(&:present?) : true) }

        metadata.merge(read_options)
      end

      private

      # MANDATORY FIELDS

      # For alternate identifiers, the Bolognese gem requires a hash with a key
      # of 'identifier' instead of 'alternate_identifier' like you might expect.
      # The identifierType is used to identify whether it should create an
      # <identfier/> or <alternateIdentifier/> tag.
      # @param [Hash] - metadata attributes from the work.to_json
      def read_hyrax_work_identifiers(attrs)
        [{ "identifier" => attrs.fetch('id'), "identifierType" => "A local Hyrax object identifier" }]
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @param [String] - any draft doi created by the VaultDataciteRegistrar
      # @return [String] - the existing or new DOI
      def draft_or_existing_doi(attrs, draft_doi)
        doi = attrs.fetch('doi', nil)&.first || draft_doi
        normalize_doi(doi)
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Array <Hash>] - info on the work's creator to be included in the Datacite XML
      # [{ "name" => "Lastname, Firstname", "nameIdentifiers" => [], "affiliation" => [] }]
      def read_hyrax_work_creators(attrs)
        if attrs.fetch("creator", []).any?(&:present?)
          attrs.fetch("creator").map do |val|
            val.class == Hash ? name_identifier_hash(val) : get_one_author(sanitize(val))
          end
        else
          get_one_author(":unav")
        end
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [String] - The year of the work's create_date
      def read_hyrax_work_create_date(attrs)
        Date.parse(attrs.fetch('create_date')).year.to_s
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Hash] - The resourceType and resourceTypeGeneral attributes to be used in the Datacite XML
      def read_hyrax_work_resource_types(attrs)
        type = attrs.fetch('resource_type', [])
        return { "resourceType" => ":unav", "resourceTypeGeneral" => "Other" } if type.empty?
        label = Hyrax::ResourceTypesService.label(type.first)
        GENERAL_TYPES.keys.include?(label) ? general_type = GENERAL_TYPES[label] : general_type = "Other"
        { "resourceType" => label, "resourceTypeGeneral" => general_type }
      end

      # RECOMMENDED_FIELDS

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Array <Hash>] - A list of contributors
      # [{ "name" => "Lastname, Firstname", "nameIdentifiers" => [], "affiliation" => [] }]
      def read_hyrax_work_contributors(attrs)
        return [] unless attrs.fetch("contributor", []).any?(&:present?)
        attrs.fetch("contributor").map do |val|
          val.class == Hash ? name_identifier_hash(val) : get_one_author(sanitize(val))
        end
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Array <Hash>] - A list of the work's subjects with attributes for XML tags
      # For URIs: {"subject"=>"label", "subjectScheme"=>"FAST", "schemeUri"=>"http://id.worldcat.org/fast", "valueUri"=>"x" }
      # For textual values: {"subject"=>"Subject string"}
      def read_hyrax_work_subjects(attrs)
        # Fetch values from subject field and add them to keyword values
        subjects = attrs.fetch("subject", nil).map do |val|
          val.class == Hash ? subject_identifier_hash(val) : { "subject" => sanitize(val) }
        end
        subjects + super
      end

      # @param [String] - a single value from the subject field
      # @return [Hash] - formatted hash to be transformed into DataCite XML
      def subject_identifier_hash(val)
        uri = val['id']
        {
            "subject" => get_label(uri),
            "subjectScheme" => "FAST",
            "schemeUri" => "https://id.worldcat.org/fast",
            "valueUri" => uri
        }
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Array <Hash> or Nil] - hash of attributes to be included in DataCite XML like
      # [{ "geoLocationPlace" => "label", "geoLocationPoint" => { "pointLongitude" => "XX", "pointLatitude" => "XX" } }]
      def read_hyrax_work_geo_locations(attrs)
        return [] unless (attrs.fetch("coordinates", []).any?(&:present?) or
            attrs.fetch("geographic_coverage", []).any?(&:present?))
        places = attrs.fetch("geographic_coverage")
        coordinates = attrs.fetch("coordinates",[])
        places.map { |place| build_place_and_coordinates(place, coordinates) } if places
      end

      # @param [String] - a single value from the geographic coverage field
      # @param [Array <String>] - all values in the coordinates field
      def build_place_and_coordinates(place, coordinates)
        if place.class == Hash # val is a URI
          uri = place['id']
          label = get_label(uri)
          hash = { "geoLocationPlace" => label }
          if get_coordinates(uri).any?
            latitude, longitude = get_coordinates(uri)
            hash["geoLocationPoint"] = { "pointLongitude" => longitude, "pointLatitude" => latitude }
          end
        else # val is a String
         # If there is only one value in geographic_coverage
         # and coordinates, then we can match them together
          if coordinates.count == 1
            hash = { "geoLocationPlace" => place }
            hash["geoLocationPoint"] = {
                "pointLongitude" => coordinates.first.split(", ").last,
                "pointLatitude" => coordinates.first.split(", ").first
            }
          end
        end
        hash
      end

      # Gets coordinates from the RDF/XML page for a FAST URI
      # @param [String] - the FAST URI
      # @return [Array <String>] - the latitude and longitude coordinates
      def get_coordinates(uri)
        data = open(uri).read
        latitude = data.match(/<schema:latitude>(.+)<\/schema:latitude>/)[1]
        longitude = data.match(/<schema:longitude>(.+)<\/schema:longitude>/)[1]
        # Omit coordinates if one is "?"
        # This happens for some locations such as https://id.worldcat.org/fast/1204373.rdf.xml
        return [] if (latitude == "?" || longitude == "?")
        [latitude, longitude]
      rescue NoMethodError # This happens if a place has no coordinates
        return []
      end

      # @param [Hash] - metadata attributes from the work.to_json
      # @return [Array <Hash>] - date created values/attributes to be included in DataCite XML
      def read_hyrax_work_dates(attrs)
        dates = attrs.fetch('date_created', [])
        return [] if dates.empty? or dates.all?("unknown") or dates.all?("no date")
        dates.map do |date|
          { "dateType" => "Created", "date" => convert_to_iso_standard(date) }
        end
      end

      # Converts an EDTF date string into RKMS-ISO8601 standard needed by DataCite
      # (see https://support.datacite.org/docs/datacite-metadata-schema-v44-recommended-and-optional-properties#8-date)
      # @param [String] - An EDTF date string from the date created field
      # @return [String] - the same date expressed in in RKMS-ISO8601 standard
      def convert_to_iso_standard(date_string)
        parsed_date = ::EdtfDateService.new(date_string).parsed_date
        return date_string if parsed_date.class == Date && !open_interval?(date_string)
        first_date = parsed_date.try(:begin)
        last_date = parsed_date.try(:end)
        if [EDTF::Decade, EDTF::Century].include?(Date.edtf(date_string.gsub('X','x')).class)
          # Use year precision
          first_date = first_date.year
          last_date = last_date.year
        elsif Date.edtf(date_string).class == EDTF::Interval or open_interval?(date_string)
          # If a normal interval, split the original date string to preserve the same
          # level of (year, month, day) precision. If an open interval, omit the ".."
          # to conform to RKMS-ISO8601 standard. See
          # https://www.ukoln.ac.uk/metadata/dcmi/collection-RKMS-ISO8601/
          first_date = (date_string.split('/').first == ".."  ? "" : date_string.split('/').first)
          last_date = (date_string.split('/').last == ".." ? "" : date_string.split('/').last)
        end
        "#{first_date}/#{last_date}"
      end

      def open_interval?(date)
        date.starts_with?("..") or date.ends_with?("..")
      end

      # OPTIONAL FIELDS

      def read_hyrax_work_rights_list(attrs)
        rights_statement = attrs.fetch('rights_statement', nil)
        return [] unless rights_statement.present?
        label = Hyrax.config.rights_statement_service_class.new.label(rights_statement.first)
        { "rights" => label, "rightsUri" => rights_statement.first }
      end

      def read_hyrax_work_formats(attrs)
        return [] unless attrs.fetch("mime_types").present?
        attrs.fetch("mime_types")
      end

      def read_hyrax_work_languages(attrs)
        attrs.fetch('language').first
      end

      # UTILITY METHODS
      # Methods used by multiple fields (mostly for working with FAST URIs)

      # Get the RDF label from FAST. We could use the ActiveTriples gem to fetch
      # the label but this is faster.
      def get_label(uri)
        open(uri).read.match(/<skos:prefLabel>(.+)<\/skos:prefLabel>/)[1]
      end

      def fst_identifier(uri)
        uri.match(/https?:\/\/id\.worldcat\.org\/fast\/(\d{1,8})\/?/)[1]
      end

      def name_identifier_hash(val)
        uri = val['id']
        {
            "name" => get_label(uri),
            "nameIdentifiers" => [
                {
                    "nameIdentifier" => fst_identifier(uri),
                    "nameIdentifierScheme" => "FAST",
                    "schemeUri" => "https://id.worldcat.org/fast"
                }
            ],
            "affiliation"=>[]
        }
      end

    end
  end
end

