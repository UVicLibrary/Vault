module EdtfDateHelper

  # Used by catalog_controller (line 101) to render the date_created attribute of search results

  # @return [String] - A joined list of humanized EDTF dates
  def humanize_date_created(options={})
    edtf_dates = options[:document].date_created

    return [] unless edtf_dates.any?

    edtf_dates.map { |date| EdtfDateService.new(date).humanized rescue date }.join(",")
  end

end