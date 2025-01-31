# Generated via
#  `rails generate curation_concerns:work GenericWork`
module Hyrax
  module Actors
    class GenericWorkActor < Hyrax::Actors::BaseActor

      def apply_save_data_to_curation_concern(env)
        cleaned_attributes = clean_attributes(env.attributes)
        env.curation_concern.attributes = clean_controlled_properties(env, cleaned_attributes)
        # save(env)
        # Bug: removing download permissions occasionally makes a work private.
        # To fix it, we re-add public read permissions if the visibility is set to public
        # (maybe has to do with the order that permissions from hydra-access-controls
        # and blacklight-access_controls gems are applied?)
        reapply_public_read_access(env)
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
        attributes
      end

      def reapply_public_read_access(env)
        permissions = env.curation_concern.permissions.map(&:to_hash).dup
        public_view_access = { name: "public", type: "group", access: "read" }

        if env.attributes['visibility'] == "open" && permissions.exclude?(public_view_access)
          permissions.push(public_view_access)
          # Need to reset permissions before setting them, or else we can end
          # up with multiples of exactly the same access type. Same logic
          # is used in app/jobs/toggle_downloads_job
          env.curation_concern.permissions = []
          env.curation_concern.permissions_attributes = permissions.uniq
          save(env)
        end
      end

    end
  end
end
