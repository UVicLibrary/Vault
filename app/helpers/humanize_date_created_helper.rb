module HumanizeDateCreatedHelper
  require 'edtf-humanize'
  require 'edtf'

  def humanize_date_created(options={})
    edtf_dates = options[:document].edtf_date('date_created')
    if edtf_dates.length > 1
      edtf_dates.join(",")
    else
      edtf_dates.first
    end
  end

end