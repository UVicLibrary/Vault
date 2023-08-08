module Hyrax
  module GoogleMapBehavior
    def getsolr
      works = @member_docs.select {|work| work["coordinates_tesim"].present?}
      @coordinates = works.sort!{|a,b| a['title_tesim'][0].downcase <=> b['title_tesim'][0].downcase}
    end
  end
end