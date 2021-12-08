class EdtfDateService
  # A class for working with EDTF dates. See https://www.loc.gov/standards/datetime/
  require 'edtf'

  class InvalidEdtfDateError < StandardError; end

    def initialize(edtf_string)
      @edtf_string = edtf_string
      @parsed_date = parse_date(edtf_string)
    end

    # Return date in solr format
    def solr_date_range
      if ([EDTF::Interval, EDTF::Decade, EDTF::Century, EDTF::Season].include?(@parsed_date.class)) or season_interval?(@edtf_string)
        @parsed_date.map{|d| d.strftime("%FT%TZ")}
      elsif @parsed_date.class == Date
        Array.wrap(@parsed_date.strftime("%FT%TZ"))
      end
    end

    # Returns first solr date
    def first_solr_date
      solr_date_range.first if solr_date_range
    end

    def year_range
      case @parsed_date.class.name
      when "Date"
        Array.wrap(@parsed_date.year.to_i)
      when "String"
        nil
      else
        @parsed_date.map { |d| d.year.to_i }.uniq
      end
    end

    def first_year
      year_range.first if year_range
    end

    # Returns human-readable date (string). See edtf-humanize:
    # https://github.com/duke-libraries/edtf-humanize
    def humanized
      case @parsed_date.class.name
      when "EDTF::Season"
        humanized_season(@parsed_date)
      when "EDTF::Interval"
        if season_interval?(@edtf_string)
          humanized_season_interval(@edtf_string)
        elsif approx_and_uncertain?(@edtf_string)
          humanized_approx_and_uncertain_interval
        else
          @parsed_date.humanize.gsub('circa','approximately')
        end
      when "NilClass" # cannot parse
        @parsed_date + " (cannot parse)"
      when "String" # "unknown" or "no date"
        @parsed_date
      when "Date"
        if approx_and_uncertain?(@edtf_string)
          humanized_approx_and_uncertain_date(@parsed_date.humanize)
        else
          @parsed_date.humanize.gsub('circa','approximately')
        end
      else
        @parsed_date.humanize.gsub('circa','approximately')
      end
    end

    private

      def approx_and_uncertain?(date_string)
        date_string.include?('%')
      end

      def humanized_approx_and_uncertain_date(parsed_date)
        parsed_date.gsub('circa','approximately') << '?'
      end

      def humanized_approx_and_uncertain_interval
        strings = @parsed_date.humanize.split("to ").map do |string|
          string = string.strip
          humanized_approx_and_uncertain_date(string)
        end
        strings.join(" to ")
      end

      def season?(date_string)
        Date.edtf(date_string).class == EDTF::Season
      end

      def season_interval?(date_string)
        season?(date_string.split("/").first) and season?(date_string.split("/").second)
      end

      def parse_date(date_string)
        date_string = date_string.gsub('%','~')
        if date_string == "unknown" or date_string == "no date"
          date_string
        elsif season_interval?(date_string)
          first_season = Date.edtf(date_string.split("/").first)
          last_season = Date.edtf(date_string.split("/").last)
          # edtf can't parse season intervals, so we create an interval using the first season's
          # first date and the last season's last date
          EDTF::Interval.new(first_season.first, last_season.last)
        elsif Date.edtf(date_string).nil? # Invalid date
          if date_string.include? "#"
            raise InvalidEdtfDateError.new("Could not parse date: #{date_string}. Date includes #.")
          else
            raise InvalidEdtfDateError.new("Could not parse date: #{date_string}. If date is unknown, use \"unknown\" or \"no date\"")
          end
        else
          # modify date so that the interval encompasses the years on the last interval date
          temp_date = date_string.gsub('/..','').gsub('%','?').gsub(/\/$/,'')
          date = temp_date.include?("/") ? temp_date.gsub(/([0-9]+X+\/)([0-9]+)(X+)/){"#{$1}"+"#{$2.to_i+1}"+"#{$3}"}.gsub("X","u") : temp_date
          if match = date[/\d{3}u/] # edtf can't parse single u in year (e.g. 192u), so we replace it
            date.gsub!(match, match.gsub("u","0"))
          end
          Date.edtf(date)
        end
      end

      def humanized_season(season)
        season.humanize.split(" ").map(&:capitalize).join(", ")
      end

      def humanized_season_interval(date_string)
        first_season = Date.edtf(date_string.split("/").first)
        last_season = Date.edtf(date_string.split("/").last)
        "#{humanized_season(first_season)} to #{humanized_season(last_season)}"
      end

end