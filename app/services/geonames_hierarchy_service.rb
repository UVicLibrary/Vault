class GeonamesHierarchyService
  class << self

    # Service for using Geonames to return a hierarchy of locations for collection indexing
    # and sorting. For example, when called on Victoria, British Columbia Canada, it should return
    # ["Victoria", "Vancouver Island", "British Columbia", "Canada", "North America"]

    # @param [String] The full uri as indexed in based_near_tesim, e.g. "http://sws.geonames.org/6174041/"
    # @return [Array] of place name, region name (if any), admin name, country name, continent name
    def call(uri)
      @geonames_id = uri.gsub(/https?:\/\/sws.geonames.org\//,'').split('/').first
      @item = Qa::Authorities::Geonames.new.find(@geonames_id)
      hierarchy
    end

    private

    def hierarchy
      # Index "Vancouver Island" if place is on Vancouver Island
      if within?("8630140") # The Geonames id for Vancouver Island
        # Call reject to omit empty strings
        [name, "Vancouver Island", province, country, continent].reject(&:blank?).uniq
      else
        [name, province, country, continent].reject(&:blank?).uniq
      end
    end

    # @return [String] Name according to Geonames
    def name
      @item['name']
    end

    # @return [String] The administrative region (e.g. province/territory in Canada, state in USA)
    def province
      @item['adminName1']
    end

    # @return [String] country name
    def country
      @item['countryName']
    end

    # @return [String] continent name
    def continent
      get_hierarchy(@geonames_id)[1]['name']
    end

    # Method for checking if the item is within another region/location
    # @param [String] The geonames ID of the outer bounding region
    # @return [Boolean] whether the place that the service was called on falls within the bounds
    # of the outer region
    def within?(bounding_id)
      outer = Qa::Authorities::Geonames.new.find(bounding_id)['bbox']
      if @item['bbox']
        # coordinates that mark boundaries of the place you're checking
        inner = @item['bbox']
        inner['west'].between?(outer['west'], outer['east']) && inner['east'].between?(outer['west'], outer['east']) &&
            inner['north'].between?(outer['south'], outer['north']) && inner['south'].between?(outer['south'], outer['north'])
      elsif @item['lat'] && @item['lng']
        # coordinates that mark boundaries of what you're checking against
        @item['lat'].to_i.between?(outer['south'],outer['north']) && @item['lng'].to_i.between?(outer['west'], outer['east'])
      else # Place does not have coordinates so we can't check
        false
      end
    end

    # Make a call to Geonames' hierarchy API: https://www.geonames.org/export/place-hierarchy.html,
    # used to retrieve the continent name
    # @param [String] the Geonames ID
    # @return [Hash] The regions containing the location described by @geonames_id
    def get_hierarchy(geonames_id)
      url = "http://api.geonames.org/hierarchyJSON?geonameId=#{geonames_id}&username=#{Settings.geonames_username}"
      response = JSON.parse(Faraday.get(url).body)
      response['geonames']
    end

  end
end