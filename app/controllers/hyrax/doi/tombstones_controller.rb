# frozen_string_literal: true
module Hyrax
  module DOI
    class TombstonesController < ::ApplicationController

      with_themed_layout 'dashboard'

      def new
        authorize! :destroy, params[:hyrax_id]
        # Renders the form for a new tombstones using params passed in from works controller
        @tombstone = Tombstone.new(doi: params[:doi], hyrax_id: params[:hyrax_id])
      end

      def create
        @tombstone = Tombstone.create(tombstone_params)
        send_datacite_request
        ActiveFedora::Base.find(@tombstone.hyrax_id).destroy!
        Hyrax.config.callback.run(:after_destroy, @tombstone.hyrax_id, current_user, warn: false)
        # Escaping the DOI will cause errors, so we unescape it
        redirect_to CGI::unescape(main_app.hyrax_doi_tombstone_path(doi: @tombstone.doi)), notice: "Work was deleted and tombstone was successfully created for DOI #{@tombstone.doi}."
      end

      def show
        @tombstone = Tombstone.find_by(doi: params[:doi].downcase)
        @metadata = Hash.from_xml(datacite_client.get_metadata(@tombstone.doi).to_s)['resource']
        # Render the tombstones, including reason and citation
        render 'show', layout: 'hyrax'
      end

      private

      def send_datacite_request
        datacite_client.create_tombstone_doi(@tombstone.doi)
      end

      def datacite_client
        Hyrax::DOI::DataCiteTombstoneClient.new(
          username: Hyrax::DOI::DataCiteRegistrar.username,
          password: Hyrax::DOI::DataCiteRegistrar.password,
          prefix: Hyrax::DOI::DataCiteRegistrar.prefix,
          base_url: base_url,
          mode: Hyrax::DOI::DataCiteRegistrar.mode
        )
      end

      def tombstone_params
        params.require(:tombstone).permit(:doi, :hyrax_id, :reason)
      end

      def base_url
        # In Docker dev environment, our app is at localhost:3000 so we include the port
        hostname = Rails.env.development? ? request.host_with_port : request.hostname
        protocol = Site.account&.ssl_configured ? "https" : "http"
        "#{protocol}://#{hostname}"
      end

    end
  end
end