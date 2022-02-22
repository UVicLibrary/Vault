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
  # Based on the edtf gem by Sylvester Keil
  # (https://github.com/inukshuk/edtf-ruby)
  # and the edtf-humanize gem from Duke Libraries.
  # (https://github.com/duke-libraries/edtf-humanize)

  require 'edtf'

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
    # Open-ended date intervals
    if @edtf_string.include?("/..")
      "Post #{@parsed_date.humanize.capitalize}"
    elsif @edtf_string.include?("../")
      "Before #{@parsed_date.humanize.capitalize}"
    else
      case @parsed_date.class.name
      when "EDTF::Season"
        humanized_season(@parsed_date)
      when "EDTF::Interval"
        if season_interval?(@edtf_string)
          humanized_season_interval(@edtf_string)
        elsif century_or_decade_interval?(@edtf_string)
          humanized_century_or_decade_interval(@edtf_string)
        elsif approx_and_uncertain?(@edtf_string)
          humanized_approx_and_uncertain_interval
        else
          @parsed_date.humanize.gsub('circa','approximately')
        end
      when "EDTF::Century", "EDTF::Decade"
        if @edtf_string =~ /(X?|x?)/
          humanized_uncertain_century_or_decade(@parsed_date)
        else
          @parsed_date.humanize.gsub('circa','approximately')
        end
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
end

  class InvalidEdtfDateError < StandardError; end

  def self.error_classes
    [InvalidEdtfDateError]
  end

  private

  def approx_and_uncertain?(date_string)
    date_string.include?('%')
  end

  def humanized_approx_and_uncertain_date(parsed_date)
    parsed_date.humanize.gsub('circa','approximately') << '?'
  end

  def humanized_uncertain_century_or_decade(parsed_date)
    parsed_date.humanize.gsub('circa','approximately') << '?'
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

  def century?(date_string)
    Date.edtf(date_string).class == EDTF::Century
  end

  def decade?(date_string)
    Date.edtf(date_string).class == EDTF::Decade
  end

  def season_interval?(date_string)
    season?(date_string.split("/").first) and season?(date_string.split("/").second)
  end

  def century_or_decade_interval?(date_string)
    first_date = date_string.split("/").first
    last_date = date_string.split("/").second
    (century?(first_date) and century?(last_date)) ||
        (decade?(first_date) and decade?(last_date))
  end

  def century_interval?(date_string)
    century?(date_string.split("/").first) and century?(date_string.split("/").second)
  end

  def decade_interval?(date_string)
    decade?(date_string.split("/").first) and decade?(date_string.split("/").second)
  end

  def parse_date(date_string)
    date_string = date_string.gsub('%','~')
    if date_string == "unknown" or date_string == "no date"
      date_string
    elsif date_string.include? "/.." # This is an open-ended interval such as "1867/.. "
      # Only index the first date
      Date.edtf(date_string.split("/").first)
    elsif date_string.include? "../"
      Date.edtf(date_string.split("/").last)
    elsif season_interval?(date_string) or century_interval?(date_string) or decade_interval?(date_string)
      # edtf can't parse season or century intervals, so we create an interval using the first season's
      # first date and the last season's last date
      first_date = Date.edtf(date_string.split("/").first)
      last_date = Date.edtf(date_string.split("/").last)
      EDTF::Interval.new(first_date.first, last_date.last)
    elsif Date.edtf(date_string).nil? # Invalid date
      if date_string.include? "#"
        raise InvalidEdtfDateError.new("Could not parse date: \"#{date_string}.\" Date includes #, please use X or another alternative.")
      else
        raise InvalidEdtfDateError.new("Could not parse date: \"#{date_string}.\" If date is unknown, use \"unknown\" or \"no date\"")
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

  def humanized_century_or_decade_interval(date_string)
    first_date = Date.edtf(date_string.split("/").first)
    last_date = Date.edtf(date_string.split("/").last)
    "#{first_date.humanize} to #{last_date.humanize}"
  end

end
