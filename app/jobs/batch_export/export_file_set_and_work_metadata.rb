def write_file_set_and_work_metadata(file_set, dest)
  @csv_headers = ['type'] + work_fields
  @csv_array   = [@csv_headers.join(',')]
  doc = SolrDocument.find(file_set.parent.id)
  add_line doc
  file_doc = ::SolrDocument.find file_set.id
  add_line file_doc
  File.open(dest, 'w') { |file| file.write(@csv_array.join("\n")) }
end

def add_line doc
  line_hash = {}
  line_hash['type'] = doc._source[:has_model_ssim].first
  work_fields.each do |field|
    line_hash[field] = create_cell doc, field
  end
  @csv_array << line_hash.values_at(*@csv_headers).map { |cell| cell = '' if cell.nil?; "\"#{cell.gsub("\"", "\"\"")}\"" }.join(',')
end

def work_fields
  @fields ||=  available_works.map { |work| work.new.attributes.keys }.flatten.uniq - excluded_fields
end

def excluded_fields
  %w[date_uploaded date_modified head tail state proxy_depositor on_behalf_of arkivo_checksum label
       relative_path import_url part_of resource_type access_control_id
       representative_id thumbnail_id rendering_ids admin_set_id embargo_id
       lease_id]
end

def available_works
  # Hyrax::QuickClassificationQuery.new(User.find_by(email: "tjychan@uvic.ca")).authorized_models
  @available_works ||= [GenericWork]
end

def create_cell w, field
  if field.include? 'date' or field == "chronological_coverage"
    if w._source[field+'_tesim'].is_a?(Array)
      w._source[field+'_tesim'].join('|')
    else
      w._source[field+'_tesim']
    end
  elsif w.respond_to?(field.to_sym)
    if w.send(field).is_a?(Array)
      w.send(field).join('|')
    else
      w.send(field)
    end
  end
end