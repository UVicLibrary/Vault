class ReindexFileSetsJob < ActiveJob::Base
  # reindex all file sets in a collection
  def perform(collection_id)
    works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
    works.each do |w|
      w.file_sets.each { |fs| fs.update_index }
    end
  end

end