class EdtfDateService
  # A class for working with EDTF dates. See https://www.loc.gov/standards/datetime/
  require 'edtf'

    def initialize(edtf_string)
      @edtf_string = edtf_string
      @parsed_date = parse_date(edtf_string)
    end

    # Return date in solr format
    def solr_date_range
      case @parsed_date.class.name
      when "EDTF::Interval"
        @parsed_date.map{|d| d.strftime("%FT%TZ")}
      when "EDTF::Season"
        @parsed_date.map{|d| d.strftime("%FT%TZ")}
      when "Date"
        Array.wrap(@parsed_date.strftime("%FT%TZ"))
      end
    end

    # Returns first solr date
    def first_solr_date
      solr_date_range.first if solr_date_range
    end

    def year_range
      case @parsed_date.class.name
      when "EDTF::Interval"
        @parsed_date.map { |d| d.year.to_i }.uniq
      when "EDTF::Season"
        @parsed_date.map { |d| d.year.to_i }.uniq
      when "Date"
        Array.wrap(@parsed_date.year.to_i)
      end
    end

    def first_year
      year_range.first if year_range
    end

    # Returns human-readable date (string). See edtf-humanize:
    # https://github.com/duke-libraries/edtf-humanize
    def humanized
      if season_interval?(@edtf_string)
        humanized_season_interval(@edtf_string)
      elsif @parsed_date.nil?
        @edtf_string
      else
        # Capitalize seasons
        seasons = ["spring", "summer", "autumn", "winter"]
        @parsed_date.humanize.split(" ").each { |word| word.capitalize! if seasons.include?(word) }.join(" ")
      end
    end

    private

      def season?(date_string)
        Date.edtf(date_string).class == EDTF::Season
      end

      def season_interval?(date_string)
        season?(date_string.split("/").first) and season?(date_string.split("/").second)
      end

      def parse_date(date_string)
        if season_interval?(date_string)
          first_season = Date.edtf(date_string.split("/").first)
          last_season = Date.edtf(date_string.split("/").last)
          # edtf can't parse season intervals, so we create an interval using the first season's
          # first date and the last season's last date
          EDTF::Interval.new(first_season.first, last_season.last)
        else
          # modify date so that the interval encompasses the years on the last interval date
          temp_date = date_string.gsub('/..','').gsub('%','?~').gsub(/\/$/,'')
          date = temp_date.include?("/") ? temp_date.gsub(/([0-9]+X+\/)([0-9]+)(X+)/){"#{$1}"+"#{$2.to_i+1}"+"#{$3}"}.gsub("X","u") : temp_date
          date = date.gsub("X","u").gsub('?','')
          if match = date[/\d{3}u/] # edtf can't parse single u in year (e.g. 192u), so we replace it
            date.gsub!(match, match.gsub("u","0"))
          end
          Date.edtf(date)
        end
      end

      def humanized_season_interval(date_string)
        first_season = Date.edtf(date_string.split("/").first)
        last_season = Date.edtf(date_string.split("/").last)
        "#{first_season.humanize.capitalize} to #{last_season.humanize.capitalize}"
      end

end