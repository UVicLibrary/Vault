# frozen_string_literal: true
class EdtfDateService
  # A service for indexing and humanzing EDTF dates
  # Used by app/indexers/work_indexer for date_created and
  # chronological_coverage.
  # (see https://www.loc.gov/standards/datetime/).
  #
  # For extended examples of different types of dates and
  # what they index as, see
  # spec/services/edtf_date_service_spec.rb
  #
  # For more on expected behaviour, see
  # https://connect.uvic.ca/sites/library/units/tech/cat/_layouts/15/WopiFrame2.aspx?sourcedoc=/sites/library/units/tech/cat/Documents/Metadata%20Documents/Vault/Vault_EDTF_Table.xlsx&action=default
  #
  # Based on the edtf gem by Sylvester Keil
  # (https://github.com/inukshuk/edtf-ruby)
  # and the edtf-humanize gem from Duke Libraries.
  # (https://github.com/duke-libraries/edtf-humanize)

  require 'edtf'

    def initialize(date_string)
      # We treat unspecified decades (199X) and unspecified centuries (19XX) the same as
      # EDTF::Decade (199x) and EDTF::Century (19XX) respectively
      @date_string = date_string.downcase
      @parsed_date = parse_date(@date_string)
    end

    # The first possible date in Solr datetime format for sorting
    # @return [String] - a Solr-formatted datetime
    # See https://solr.apache.org/guide/solr/latest/indexing-guide/date-formatting-math.html
    def first_solr_date
      if [EDTF::Interval, EDTF::Decade, EDTF::Century, EDTF::Season].include?(@parsed_date.class)
        if @parsed_date.class == EDTF::Interval && @parsed_date.open?
          @parsed_date.from.strftime("%FT%TZ")
        else
          @parsed_date.first.strftime("%FT%TZ")
        end
      elsif @parsed_date.class == Date
        @parsed_date.strftime("%FT%TZ")
      end
    end

    # @return [Array <Integer>] - a range of years for blacklight_range_limit gem
    def year_range
      # For open-ended intervals such as "1900/.."
      if @parsed_date.class == EDTF::Interval && @parsed_date.open?
        Array.wrap(@parsed_date.from.year.to_i)
      else
        case @parsed_date.class.name
        when "Date"
          Array.wrap(@parsed_date.year.to_i)
        when "String"
          nil
        else
          @parsed_date.map { |d| d.year.to_i }.uniq
        end
      end
    end

    def first_year
      year_range.first if year_range
    end

    # Returns human-readable date (string). See edtf-humanize:
    # https://github.com/duke-libraries/edtf-humanize
    def humanized
      # Open-ended date intervals
      if "#{@date_string}".include?("../")
        result = "Before #{@parsed_date.humanize.capitalize}"
      elsif "#{@date_string}".include?("/..")
        result = @parsed_date.humanize.capitalize
      else
        case @parsed_date
        when EDTF::Interval
          from_date = @date_string.split('/')[0].gsub('/..','open')
          to_date = @date_string.split('/')[1].gsub('/..','open')
          if pre_1000_interval?
            from = parse_date_before_1000(from_date).humanize.gsub(/^0/,'')
            to = parse_date_before_1000(to_date).humanize.gsub(/^0/,'')
          else
            from = Date.edtf(from_date).humanize
            to = Date.edtf(to_date).humanize
          end
          result = "#{from}#{I18n.t('edtf.terms.interval_connector_day')}#{to}"
        when EDTF::Century, EDTF::Decade, EDTF::Season
          result = apply_humanized_approximate_or_uncertain(@parsed_date, @date_string.last)
        when String # "unknown" or "no date"
          result = @parsed_date
        when Date
          result = apply_humanized_approximate_or_uncertain(@parsed_date.humanize, @date_string.last)
        end
      end
      delete_prefix(result)
    end

    class InvalidEdtfDateError < StandardError; end

    def self.error_classes
      [InvalidEdtfDateError]
    end

    def parsed_date
      @parsed_date
    end

    private

      def parse_date(date_string)
        # Remove all uncertainty and approximation markers before parsing.
        # They will be added back later if necessary.
        date_string = strip_markers(date_string.gsub('/..','/open'))
        return Date.edtf(date_string) if Date.edtf(date_string) && !interval?

        if date_string == "unknown" or date_string == "no date"
          date_string
        elsif date_string.include? "../" # Open start interval
          last_date = date_string.split("/").last
          before_1000?(last_date) ? parse_date_before_1000(last_date) : Date.edtf(last_date)
        elsif interval?
          parse_interval(date_string)
        elsif before_1000?(date_string)
          if date_string.end_with?('xx'||'XX') # century
            EDTF::Century.new(date_string.gsub('xx','00').to_i)
          elsif date_string.end_with?('x'||'XX') # decade
            EDTF::Decade.new(date_string.gsub('x','0').to_i)
          else
            parse_date_before_1000(date_string)
          end
        else # Date is still invalid despite best attempt to parse
          if date_string.include? "#"
            raise InvalidEdtfDateError.new("Could not parse date: \"#{date_string}.\" Date includes #, please use X or another alternative.")
          else
            raise InvalidEdtfDateError.new("Could not parse date: \"#{date_string}.\" If date is unknown, use \"unknown\" or \"no date\"")
          end
        end
      end

      # Delete the 0 at the front of a pre-1000 date, e.g. 0900 -> 900
      def delete_prefix(string)
        return string unless years = string.scan(/0\d{3}/)
        string_dup = string.dup
        years.to_a.each { |match| string_dup.gsub!(match, match.delete_prefix('0')) }
        string_dup
      end

      # Remove all uncertainty and approximation markers
      def strip_markers(date_string)
        markers = ['%','?','~']
        dup = date_string.dup
        markers.each do |marker|
          dup.gsub!(marker,'')
        end
        dup
      end

      def parse_interval(date_string)
        if pre_1000_interval?
          first_date = parse_date_before_1000(date_string.split("/").first)
          last_date = if date_string.split("/").last == "open"
                        date_string.split("/").last.to_sym
                      elsif before_1000?(date_string.split("/").last)
                        parse_date_before_1000(date_string.split("/").last)
                      else
                        Date.edtf(date_string.split("/").last)
                      end
        elsif season_interval? || century_interval? || decade_interval?
          # edtf-ruby doesn't like century or decade intervals, so we call
          # #first and #last to get normal dates
          first_date = Date.edtf(date_string.split("/").first).first
          last_date = Date.edtf(date_string.split("/").last).last
        else # Just an interval of normal dates
          first_date = Date.edtf(date_string).from
          last_date = Date.edtf(date_string).to
        end
        if last_date != :open && first_date > last_date
          raise InvalidEdtfDateError.new("The start date of an interval cannot be after the end date.")
        end
        # Use first_date.first and last_date.last to avoid
        # ArgumentError: Intervals cannot start with: ...
        Date.edtf(date_string).nil? ? EDTF::Interval.new(first_date, last_date) : Date.edtf(date_string)
      end

      def interval?
        Date.edtf(@date_string).class == EDTF::Interval || season_interval? || century_interval? || decade_interval? || pre_1000_interval?
      end

      def season_interval?
        @date_string.include?('/') && @date_string.split('/').all? { |date| Date.edtf(date).class == EDTF::Season }
      end

      def century_interval?
        @date_string.include?('/') && @date_string.split('/').all? { |date| Date.edtf(date).class == EDTF::Century }
      end

      def decade_interval?
        @date_string.include?('/') && @date_string.split('/').all? { |date| Date.edtf(date).class == EDTF::Decade }
      end

      def pre_1000_interval?
        @date_string.include?('/') && @date_string.split('/').any? { |date| before_1000?(date) }
      end

      def before_1000?(date_string)
        /^\d{3}\b(-|\/)?|^\d{1}(X|x){2}$|^\d{2}(X|x){1}$/.match?(date_string)
      end

      # @return [Date] - the parsed date object for a single date before 1000
      # @param date_string [String] - the string to parse
      def parse_date_before_1000(date_string)
        # Ruby's default library can parse this if it's in format YYY-MM-DD (day precision)
        # but not YYY-MM (month precision) or YYY (year precision)
        if /\d{3}-\d{2}-\d{2}/.match?(date_string) # YYY-MM-DD
          date = Date.edtf(Date.parse(date_string).edtf)
        elsif /\d{3}-\d{2}$/.match?(date_string) # YYY-MM
          # Regex to parse the year and month
          year = date_string.match(/\d{3}/)[0].to_i
          month = date_string.match(/\d{2}$/)[0].to_i
          temp_date = Date.new(year, month)
          # Set month precision for edtf
          temp_date.month_precision!
          date = Date.edtf(temp_date.edtf)
        elsif /\d{3}$/.match?(date_string) # YYY
          temp_date = Date.new(date_string.to_i)
          temp_date.year_precision!
          date = Date.edtf(temp_date.edtf)
        end
        apply_approximate_or_uncertain(date, date_string.last)
        date
      end

      # Make dates before 1000 approximate or uncertain if appropropriate. Without
      # this, #humanize won't produce the expected result.
      # @param date [Date] - the datetime object to make approximate/uncertain
      # @param character [String] - the last character of a date string
      def apply_approximate_or_uncertain(date, character)
        case character
        when "~" # approximate
          date.approximate!
        when "?" # uncertain
          date.uncertain!
        when "%" # approximate and uncertain
          date.approximate!
          date.uncertain!
        end
      end

      # @return [String] - the human-readable string for an EDTF object that
      # doesn't respond to #approximate! or #uncertain!)
      # @param date [Date, EDTF::Century, EDTF::Decade, EDTF::Season] something that responds to #humanize
      # @param character [String] - the last character of a date string
      def apply_humanized_approximate_or_uncertain(date, character)
        case character
        when "~" # approximate
          I18n.t('edtf.terms.approximate_date_prefix_year') + date.humanize
        when "?" # uncertain
          date.humanize + I18n.t('edtf.terms.uncertain_date_suffix')
        when "%" # approximate and uncertain
          I18n.t('edtf.terms.approximate_date_prefix_year') + date.humanize + I18n.t('edtf.terms.uncertain_date_suffix')
        else
          date.humanize
        end
      end

end