class WorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Use thumbnails served by RIIIF
  self.thumbnail_path_service = IIIFWorkThumbnailPathService

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document

    # Convert ActiveTriples::Resource to Hyrax::ControlledVocabulary::[field name]
    # This is needed for Hyrax::DeepIndexingService
    object.attribute_names.each do |field|
      if object.controlled_properties.include?(field.to_sym) and object[field].present?
        to_controlled_vocab(field)
      end
    end

    super.tap do |solr_doc|
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.empty?

      unless object.date_created.empty?
        solr_doc['year_sort_dtsim'] = []
        object.date_created.each do |solr_date|
          # modify date so that the interval encompasses the years on the last interval date
          temp_date = solr_date.gsub('/..','').gsub('%','?~').gsub(/\/$/,'')
          date = temp_date.include?("/") ? temp_date.gsub(/([0-9]+X+\/)([0-9]+)(X+)/){"#{$1}"+"#{$2.to_i+1}"+"#{$3}"}.gsub("X","u") : temp_date
          date = date.gsub("XX-","uu-").gsub("X-", "u-").gsub("X?","u")
          if match = date[/\d{3}u/] # edtf can't parse single u in year (e.g. 192u), so we replace it
            date.gsub!(match, match.gsub("u","0"))
          end
          parsed_date = Date.edtf(date)#.first.gsub(/~|#/,'').gsub('X','0')) # Account for special characters; see https://github.com/UVicLibrary/Vault/issues/36
          # Returns formatted string with time set to midnight; e.g. Wed, 01 Jan 1913 => "1913-01-01T00:00:00Z"
          # https://lucene.apache.org/solr/guide/7_7/working-with-dates.html
          if ([EDTF::Interval, EDTF::Decade, EDTF::Century, EDTF::Season].include?(parsed_date.class))
            solr_doc['year_sort_dtsim'] += parsed_date.map{|d| d.strftime("%FT%TZ")}
            solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
          elsif parsed_date.class == Date
            solr_doc['year_sort_dtsim'] << parsed_date.strftime("%FT%TZ")
            solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
          elsif is_season?(date.split("/").first) and is_season?(date.split("/").second)
            # Season interval
            first_season = Date.edtf(date.split("/").first)
            last_season = Date.edtf(date.split("/").last)
            # edtf can't parse season intervals, so we create an interval using the first season's
            # first date and the last season's last date
            interval = EDTF::Interval.new(first_season.first, last_season.last)
            solr_doc['year_sort_dtsim'] = interval.map{|d| d.strftime("%FT%TZ")}
            solr_doc['year_sort_dtsi'] = solr_doc['year_sort_dtsim'].first
          elsif date == "unknown" or date=="no date"
            # Do not index anything in year sort
          else # parsed_date == nil
            raise "Unrecognized date in date_created field: #{date}"
          end
        end
      end
    end
  end

  private

  def is_season?(date)
    Date.edtf(date).class == EDTF::Season
  end

  # field is a symbol/controlled property
  # returns an array of Hyrax::ControlledVocabularies::[field]
  def to_controlled_vocab(field)
    if field.to_s == "based_near"
      class_name = "Hyrax::ControlledVocabularies::Location".constantize
    else
      class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
    end
    object[field] =  object[field].map do |val|
    	val.include?("http") ? class_name.new(val.strip) : val
    end
  end
end