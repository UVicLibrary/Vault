# Generated via
#  `rails generate curation_concerns:work GenericWork`
module Hyrax
  module Actors
    class GenericWorkActor < Hyrax::Actors::BaseActor
    	
    	def update(env)
        apply_update_data_to_curation_concern(env)
        apply_save_data_to_curation_concern(env)
        next_actor.update(env) && save(env) && run_callbacks(:after_update_metadata, env)
      end
      
      def apply_save_data_to_curation_concern(env)
				cleaned_attributes = clean_attributes(env.attributes)
      	env.curation_concern.attributes = clean_controlled_properties(env, cleaned_attributes)
				env.curation_concern.date_modified = TimeService.time_in_utc
			end
      
			def clean_controlled_properties(env, attributes)
				qa_attributes = {}

				env.curation_concern.controlled_properties.each do |field_symbol|
					field = field_symbol.to_s
					next unless attributes.keys.include?(field+'_attributes') or attributes.keys.include?(field)
          if attributes.keys.include?(field+'_attributes')
            qa_attributes[field] = attributes[field+'_attributes'].map do |att|
              att[1]['id']
            end
          end

          # Save string values if they exist
          if attributes.keys.include?(field)
            qa_attributes[field] = [] unless qa_attributes.has_key?(field)
            attributes[field].each { |val| qa_attributes[field].push(val) }
          end

          attributes.delete(field)
          attributes.delete(field+'_attributes')
        end
        byebug
				env.curation_concern.attributes = qa_attributes
				env.curation_concern.to_controlled_vocab
				save(env)
				attributes
			end
      
    end
  end
end
