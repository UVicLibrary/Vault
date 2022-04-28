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

      def apply_creation_data_to_curation_concern(env)
        # Previously, the "total viewable items" didn't include admins in the edit group
        # even if admins could already edit private works deposited by others.
        # This caused a mismatch between that and the true number of viewable items. This
        # includes admins explicitly if a work is set to private so that the numbers match.
        if env.curation_concern.visibility == "restricted"
          env.curation_concern.edit_groups = (env.curation_concern.edit_groups += ["admin"])
        end
        super
      end

      def clean_controlled_properties(env, attributes)
        qa_attributes = {}
        env.curation_concern.controlled_properties.each do |field_symbol|
          field = field_symbol.to_s
          # Do not include deleted attributes
					next unless attributes.keys.include?(field+'_attributes')
          filtered_attributes = attributes[field+'_attributes'].select  { |k,v| v['_destroy'].blank? }
          qa_attributes[field] = filtered_attributes.map { |attr| attr[1]['id'] }
          attributes.delete(field)
          attributes.delete(field+'_attributes')
        end
				env.curation_concern.attributes = qa_attributes
        env.curation_concern.to_controlled_vocab
        save(env)
				attributes
			end

    end
  end
end
