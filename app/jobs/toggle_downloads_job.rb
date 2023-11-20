class ToggleDownloadsJob < Hyrax::ApplicationJob

  # Allow or disallow downloads for an entire collection.
  # downloadable = true/false
  def perform(collection_id, user_email, downloadable)
    collection = Collection.find(collection_id)
    works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
    works.each do |work|
      next if work.downloadable == ActiveModel::Type::Boolean.new.cast(downloadable)
      work.downloadable = ActiveModel::Type::Boolean.new.cast(downloadable)
      work.save!
      work.file_sets.each(&:update_index)
    end
    DownloadsMailer.with(user_email: user_email.gsub('-dot-', '.'), id: collection_id, downloadable: downloadable).send_email.deliver_now
  end

end