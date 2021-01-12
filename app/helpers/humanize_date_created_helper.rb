module HumanizeDateCreatedHelper
  require 'edtf-humanize'
  require 'edtf'

  def humanize_date_created(options={})
    if options[:value] and Date.edtf(options[:value].first.gsub("X", "u").gsub("x", "u"))
      field_values = options[:value].map { |v| Date.edtf(v.gsub("X","u").gsub("x", "u")).humanize }
      field_values.join(",")
    elsif options[:value]
      options[:value].first
    end
  end


end