class ChangeCollectionsJob < ActiveJob::Base

  def perform(old_collection_id, new_collection_id)
    works = GenericWork.where(member_of_collection_ids_ssim: old_collection_id)
    new_collection = Collection.find(new_collection_id)
    works.each do |work|
      work.member_of_collections = [new_collection]
      work.save!
    end
  end

end