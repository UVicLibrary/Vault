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
    super.tap do |solr_doc|
      solr_doc['title_sort_ssi'] = object.title.first unless object.title.first.nil?

      if solr_doc['date_created_tesim']
        date = Date.edtf(solr_doc['date_created_tesim'].first.gsub(/~|#/,'').gsub('X','0')) # Account for special characters; see https://github.com/UVicLibrary/Vault/issues/36
        if date.class == EDTF::Interval
          solr_doc['year_sort_dtsim'] = solrize(date)
          solr_doc['year_sort_dtsi'] = solrize(date).first
        else # date.class == Date
          solr_doc['year_sort_dtsim'] = solr_string(date)
          solr_doc['year_sort_dtsi'] = solr_string(date)
        end
      end
    end
  end

  # Returns an array of solr_stringified dates
  def solrize(edtf_date)
    # Return an array of all years included in the interval
    years = edtf_date.map { |d| d.year.to_s }.uniq # Without .uniq, 1981-02/1981-03 would return ["1981", "1981"]
    dates_array = years.map { |y| Date.edtf(y) }     # Array of edtf date objects
    # If the start or end dates of the interval have day or month precision, keep the month/day
    if edtf_date.from.day_precision? or edtf_date.from.month_precision?
      dates_array[0] = edtf_date.from
    end
    if edtf_date.to.day_precision? or edtf_date.to.month_precision?
      dates_array[-1] = edtf_date.to unless dates_array.count == 1 # Don't overwrite the from date if from & to have the same year
    end
    dates_array.map{ |d| solr_string(d) }
  end

  # Returns formatted string with time set to midnight; e.g. Wed, 01 Jan 1913 => "1913-01-01T00:00:00Z"
  # https://lucene.apache.org/solr/guide/7_7/working-with-dates.html
  def solr_string(edtf_date)
    date_time = edtf_date.beginning_of_day.to_s.split(" ") - ["UTC"] # => ["1913-01-01", "00:00:00"]
    "#{date_time[0]}T#{date_time[1]}Z"
  end

end
