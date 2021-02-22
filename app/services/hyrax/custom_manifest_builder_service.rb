# frozen_string_literal: true
module Hyrax
  ##
  # A class responsible for converting a Hyrax::Work like thing into a IIIF
  # manifest.
  #
  # @see !{.as_json}
  class CustomManifestBuilderService < ManifestBuilderService
    # @param presenter [Hyrax::IIIFManifestPresenter]
    def sanitized_manifest(presenter:)
      # ::IIIFManifest::ManifestBuilder#to_h returns a
      # IIIFManifest::ManifestBuilder::IIIFManifest, not a Hash.
      # to get a Hash, we have to call its #to_json, then parse.
      #
      # wild times. maybe there's a better way to do this with the
      # ManifestFactory interface?
      manifest = manifest_factory.new(presenter).to_h
      hash = JSON.parse(manifest.to_json)

      hash['label'] = sanitize_value(hash['label']) if hash.key?('label')
      hash['description'] = Array(hash['description'])&.collect { |elem| sanitize_value(elem) } if hash.key?('description')
      member_presenters = presenter.member_presenters

      hash['sequences']&.each do |sequence|
        sequence['canvases']&.each do |canvas|
          canvas['label'] = sanitize_value(canvas['label'])
          canvas['images'].each do |image|
            file_set_id = image['resource']['@id'].split('/').last
            fsp = member_presenters.detect { |p| p.id == file_set_id }
            add_file_set_metadata(image, fsp)
          end
        end
      end
      hash
    end

    # @param presenter [Hyku::FileSetPresenter] -- to be refactored into Hyrax::FileSetPresenter?
      def add_file_set_metadata(image, fsp)
        image['resource']['label'] = fsp.title.first
        image['resource']['description'] = fsp.description.first

        metadata = Hyrax.config.iiif_metadata_fields.each_with_object([]) do |field, array|
            label = field.to_s.humanize.capitalize
            # Sending the format field returns too few arguments error
            if field == :format
                if fsp['format_tesim'].present?
                  value = sanitize_value(fp['format_tesim'].first)
                  array.push(label => value)
                end
                next
            end
            unless fsp.send(field).blank? or field == :description
                value = sanitize_value(fsp.send(field).first)
                array.push(label => value)
            end
        end
        image['resource']['metadata'] = metadata
      end


  end
end
