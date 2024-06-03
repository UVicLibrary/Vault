class ToggleDownloadsJob < Hyrax::ApplicationJob
  # Enable/disable public downloads for all of a collection's
  # members (works and file sets).
  #
  # @param[String] - the collection ID
  # @param[String] - email of the user who initiated the job (from dashboard/collections/edit)
  # @param[Boolean] - whether to enable or disable downloads
  def perform(collection_id, user_email, downloadable)
    setting = ActiveModel::Type::Boolean.new.cast(downloadable)
    works = GenericWork.where(member_of_collection_ids_ssim: collection_id)

    works.each do |work|
      permissions_hash = work.permissions.map(&:to_hash)

      if setting == true
        # For idempotency: no need to resave the object if permissions
        # are already what they're supposed to be
        next if permissions_hash.include?(public_download_access)
        permissions_hash.push(public_download_access)
      else # setting == false
        next if permissions_hash.exclude?(public_download_access)
        permissions_hash.delete(public_download_access)
      end

      # Clear the work permissions hash first to prevent Hydra from
      # creating duplicate relationships
      work.permissions = []
      work.permissions_attributes = permissions_hash.uniq
      work.save!

      # File sets also need to reindex the download_access_groups_ssim key
      # See app/services/indexes_download_permissions.rb
      work.file_sets.each(&:update_index)
    end
    DownloadsMailer.with(user_email: user_email.gsub('-dot-', '.'), id: collection_id, downloadable: downloadable).send_email.deliver_now
  end

  private

  def public_download_access
    { name: "public", type: "group", access: "download" }
  end
end