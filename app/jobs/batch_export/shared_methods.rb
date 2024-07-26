module BatchExport
  module SharedMethods

    def get_recent_file_ids(start_date_string, end_date_string)
      start_date = Date.parse(start_date_string).strftime("%FT%H:%M:%SZ")
      end_date = Date.parse(end_date_string).strftime("%FT%H:%M:%SZ")
      # Get all works uploaded between the start date and end date
      solr = RSolr.connect url: Blacklight.connection_config[:url]
      response = solr.get 'select', params: {
        q: "*:*",
        fq: ["has_model_ssim:FileSet","system_create_dtsi:[#{start_date} TO #{end_date}}"],
        rows: 9000,
        fl: "id"
      }
      response['response']['docs'].map { |doc| doc['id'] }
    end

    # @return a DateTime object in Solr format
    def six_months_ago
      (Date.today.beginning_of_month - 6.months).midnight.strftime("%Y-%m-%d")
    end

    # @return a DateTime object in Solr format
    def three_months_ago
      (Date.today.beginning_of_month - 3.months).midnight.strftime("%Y-%m-%d")
    end

    def skip_thumbnail?(file_set)
      # If file set is a thumbnail but not the parent's representative AND
      # the file set is an image AND
      # the representative is not an image
      parent = file_set.parent
      (file_set == parent.thumbnail && file_set != parent.representative) &&
        (file_set.image? && !parent.representative.image?)
    end

  end
end