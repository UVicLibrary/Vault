module FastUpdate
  class XlsxParser

    def initialize(filename)
      @document = SimpleXlsxReader.open(filename)
    end

    # @return [Array] of Change objects
    def parse_data
      # Skip the first 3 rows as they are headers and
      # filter out ones that have "Other Changes" in the change type since these don't affect hyrax
      rows = @document.sheets.first.rows.slurp[2...].reject { |row| row[0] == "Other Changes" }

      changes = rows.each_with_object([]) do |row, array|
        fast_id = row[1]
        uri = uri_for(fast_id)
        change_type = row[0]
        case change_type
        when "New Heading", "Modified Heading", "Obsolete"
          attributes = { type: change_type, uri: uri, label: label_for(uri), fast_id: fast_id, suggestions: nil }
        when "Deprecated", "Split"
          attributes = { type: change_type, uri: uri, label: label_for(uri), fast_id: fast_id, suggestions: get_suggestions(row) }
        else
          raise "Change type not recognized: #{row[0]}"
        end
        array << XlsxChange.new(attributes)
      end
    end

    # private

    # @return [String] The label for a FAST uri
    def label_for(uri)
      resource = ::ActiveTriples::Resource.new(uri)
      resource.fetch
      resource.rdf_label.first
    end

    # Scrubs MARC subfield codes from the string
    def get_label(string)
      regex =/7\d{2}\s+\d+\$a(.+)\$2fast/
      marc_codes = /\$([a-z]|\d)+/
      string.match(regex)[1].gsub(marc_codes, ' ')
    end

    # Extracts fast ID from a string
    def get_fast_id(string)
      regex = /fst\d{8}/
      string.match(regex)[0]
    end

    def uri_for(fast_id)
      'http://id.worldcat.org/fast/' + fast_id.gsub('fst','').gsub(/^0+/, '')
    end

    # Construct a hash with a uri and a human-readable label
    def get_suggestions(row)
      return nil unless row[8...11].select(&:present?).any?
      row[8...11].select(&:present?).map do |cell|
        { uri: uri_for(get_fast_id(cell)), label: get_label(cell) }
      end
    end
  end

  class XlsxChange
    attr_accessor :type, :uri, :label, :fast_id, :suggestions

    def initialize(options={})
      @options = options
      self.type = options[:type]
      self.uri = options[:uri]
      self.label = options[:label]
      self.fast_id = options[:fast_id]
      self.suggestions = options[:suggestions]
    end

    def attributes
      @options
    end

  end
end