module Hyrax
  module SolrDocument
    module Export
      # MIME: 'application/x-endnote-refer'
      def export_as_endnote
        text = []
        text << "%0 #{human_readable_type}"
        end_note_format.each do |endnote_key, mapping|
          if mapping.is_a? String
            values = [mapping]
          else
            values = send(mapping[0]) if respond_to? mapping[0]
            values = mapping[1].call(values) if mapping.length == 2
            values = Array.wrap(values)
          end
          next if values.blank? || values.first.nil?
          spaced_values = values.join("; ")
          text << "#{endnote_key} #{spaced_values}"
        end
        text.join("\n")
      end

      # Name of the downloaded endnote file
      # Override this if you want to use a different name
      def endnote_filename
        "#{id}.endnote"
      end

      def persistent_url
        "#{Hyrax.config.persistent_hostpath}#{id}"
      end

      def end_note_format
        {
          '%T' => [:title],
          # '%Q' => [:title, ->(x) { x.drop(1) }], # subtitles
          '%A' => [:creator],
          '%C' => [:publication_place],
          '%D' => [:date_created],
          '%8' => [:date_uploaded],
          '%E' => [:contributor],
          '%I' => [:publisher],
          '%J' => [:series_title],
          '%@' => [:isbn],
          '%U' => [:related_url],
          '%7' => [:edition],
          '%R' => [:persistent_url],
          '%X' => [:description],
          '%G' => [:language],
          '%[' => [:date_modified],
          '%9' => [:resource_type],
          '%~' => I18n.t('hyrax.product_name'),
          '%W' => Institution.name
        }
      end
      
      def export_as_ris request
        text = []
        text << "TY - #{human_readable_type}"
        ris_format(request).each do |ris_key, mapping|
          text << "#{ris_key} - " if ris_key == 'ER'
          if mapping.is_a? String
            values = [mapping]
          else
            values = send(mapping[0]) if respond_to? mapping[0]
            values = mapping[1].call(values) if mapping.length == 2
            values = Array.wrap(values)
          end
          next if values.blank? || values.first.nil?
          values.each do |value|
            text << "#{ris_key} - #{value}"
          end
          #spaced_values = values.join("; ")
          #text << "#{endnote_key} #{spaced_values}"
        end
        text.join("\n")
      end
      
      def ris_filename
        "#{id}.ris"
      end
      
      def ris_format request
        {
          'AB'	=>	[:description],
          'AU'	=>	[:creator],
          'AV'	=>	[:physical_repository],
          'CY'	=>	'Victoria, BC',
          'DA'	=>	[:date_created],
          'ET'	=>	[:edition],
          'J2'	=>	[:alternative_title],
          'KW'	=>	[:keyword],
          'L2'	=>	[:transcript],
          'L3'  =>  [:related_url],
          'LA'	=>	[:language],
          'LK'	=>	'http://'+request.host,
          'M3'	=>	'digital object',
          'N1'	=>	[:technical_note],
          'PB'	=>	[:publisher],
          'PY'	=>	[:year],
          'SN'	=>	[:isbn],
          'TI'	=>	[:title],
          'UR'	=>	request.original_url.sub('.ris',''),
          'Y1'	=>	[:date_digitized],
          'Y2'	=>	Date.today.to_s,
          'ER'	=>	[:end_of_reference]
        }
      end
    end
  end
end
