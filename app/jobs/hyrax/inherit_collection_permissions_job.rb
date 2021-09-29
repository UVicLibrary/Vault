module Hyrax
  class InheritCollectionPermissionsJob < Hyrax::ApplicationJob

    def perform(collection_id, user_email, host)
      coll = Collection.find(collection_id)
      works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
      coll_permissions = coll.permissions.map(&:to_hash)
        # Copy collection permissions to works
        works.each do |work|
          # We overwrite work's permissions with collection permissions.
          work.permissions_attributes = coll_permissions
          work.save!
          work.file_sets.each do |file_set|
            file_set.permissions_attributes = coll_permissions
            file_set.save!
          end
        end

      # Send an email when done
      ::VisibilityPermissionsMailer.with(account_host: host, user_email: user_email, id: collection_id).inherit_permissions.deliver
    end

  end
end
