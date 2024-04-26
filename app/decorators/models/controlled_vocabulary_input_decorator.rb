# OVERRIDE Hyrax v.3.4.2
ControlledVocabularyInput.class_eval do

  def build_field(value, index)
    options = input_html_options.dup
    value = value.resource if value.is_a? ActiveFedora::Base

    if value.respond_to?(:rdf_label)
      build_options(value, index, options)
      # We only want to set this data attribute for URIs since it
      # triggers the autocomplete javascript.
      options[:data]['autocomplete'] = attribute_name
    else
      # Setting options[:value] explicitly fixes a bug where string values (as in not URIs)
      # display as something like "<ActiveTripleRelation::XXXXXX>"
      options[:value] = value
      options[:data].try(:delete, 'autocomplete')
    end

    options[:required] = nil if @rendered_first_element
    options[:class] ||= []
    options[:class] += ["#{input_dom_id} form-control multi-text-field"]
    options[:'aria-labelledby'] = label_id
    @rendered_first_element = true
    text_field(options) + hidden_id_field(value, index) + destroy_widget(attribute_name, index)
  end

  def build_options_for_existing_row(_attribute_name, _index, value, options)
    options[:value] = value.rdf_label.to_s || "Unable to fetch label for #{value.rdf_subject}"
    options[:data][:label] = value.full_label || value.rdf_label
    # Omitting this option
    # options[:readonly] = true
  end

end