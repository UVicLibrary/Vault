class ReindexFileSetsJob < ActiveJob::Base
  # reindex all file sets in a collection
  def perform(work_ids)
    works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
    work_ids.each do |id|
      work = GenericWork.find(id)
      work.file_sets.each do |file_set|
        next if SolrDocument.find(file_set.id).has_key?("download_access_group_ssim")
        file_set.update_index
      end
    end
  end

end