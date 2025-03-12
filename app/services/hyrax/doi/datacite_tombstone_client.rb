module Hyrax
  module DOI
    class DataCiteTombstoneClient < Hyrax::DOI::DataCiteClient

      def initialize(username:, password:, prefix:, base_url:, mode: :production)
        @username = username
        @password = password
        @prefix = prefix
        @base_url = base_url
        @mode = mode
      end

      def create_tombstone_doi(doi)
        response = connection.put("dois/#{doi}", tombstone_doi_payload(doi).to_json, "Content-Type" => "application/vnd.api+json")
        raise Hyrax::DOI::DataCiteClient::Error.new('Failed creating DOI tombstone', response) unless response.status == 200
      end

      # If DOI's state is findable, this changes it to registered. It also
      # changes the URL to point to a tombstones page instead of a work/show page.
      # DataCite documentation:
      # https://support.datacite.org/docs/updating-metadata-with-the-rest-api
      def tombstone_doi_payload(doi)
        {
          "data": {
            "type": "dois",
            "attributes": {
              "event": "hide", # findable -> registered
              "url": tombstone_url(doi)
            }
          }
        }
      end

      def tombstone_url(doi)
        "#{@base_url}#{CGI.unescape(Rails.application.routes.url_helpers.hyrax_doi_tombstone_path(doi: doi))}"
      end

    end
  end
end
