module Hyrax
  class InheritCollectionPermissionsJob < Hyrax::ApplicationJob

    def perform(collection_id, user_email, host)
      coll = Collection.find(collection_id)
      works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
      coll_permissions = coll.permissions.map(&:to_hash)
        # Copy collection permissions to works
        works.each do |work|
          if work.permissions.map(&:to_hash) != coll_permissions
            # Clear the work permissions hash first or Hydra will create duplicate relationships
            work.permissions = []
            work.permissions_attributes = coll_permissions
            work.save!
          end
          work.file_sets.each do |file_set|
            if file_set.permissions.map(&:to_hash) != coll_permissions
              # Clear file permissions first
              file_set.permissions = []
              file_set.permissions_attributes = coll_permissions
              file_set.save!
            end
          end
        end

      # Send an email when done
      ::VisibilityPermissionsMailer.with(account_host: host, user_email: user_email, id: collection_id).inherit_permissions.deliver
    end

  end
end
