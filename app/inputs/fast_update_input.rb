# frozen_string_literal: true
class FastUpdateInput < ControlledVocabularyInput
# Inherits from Hydra Editor's MultiValueInput:
# https://github.com/samvera/hydra-editor/blob/main/app/inputs/multi_value_input.rb

  private

    # @param [Integer]
    # In the parent class, the first argument is the value. Since we only render this input for
    # new changes, the value is always nil.
    def build_field(_, index)
      options = input_html_options.dup

      options[:required] = nil if @rendered_first_element
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id
      @rendered_first_element = true
      new_label_field(options, index) + new_uri_field(attribute_name, index)
    end

    def new_label_field(options, index)
      options[:name] = name_for(index, 'label')
      @builder.text_field(attribute_name, options)
    end

    def new_uri_field(attribute_name, index)
      name = name_for(index, 'uri')
      @builder.hidden_field(attribute_name, name: name, class: 'controlled_vocabulary', data: { id: 'remote' })
    end

    def name_for(index, field)
      "#{@builder.object_name}[new_labels_and_uris][#{index}][#{field}]"
    end

    def collection
      # Set this to a placeholder so an empty box will appear even though
      # this value will be nil (since it's a new replacement).
      @collection = [options[:placeholder]]
    end

    def placeholder_text
      "Search for an entity"
    end
end
