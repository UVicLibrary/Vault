module Hyrax
  module CollectionLevelDownloads

    # Override method in hydra-access-controls/app/models/concerns/hydra/acces_controls/access_right.rb
    def authenticated_only_access?
      return false if open_access?
      self.visibility == "authenticated"
    end

    # Returns an array. First integer is how many downloadable, the second is the total no. of works.
    def count_downloadable
      works = GenericWork.where(member_of_collection_ids_ssim: self.id)
      [ works.select(&:downloadable).count, works.count ]
    end

    # Return works that are not downloadable
    def not_downloadable
      works = GenericWork.where(member_of_collection_ids_ssim: self.id)
      works.each_with_object([]) do |work, array|
        unless work.downloadable?
          array.push(work)
        end
      end
    end

  end
end


