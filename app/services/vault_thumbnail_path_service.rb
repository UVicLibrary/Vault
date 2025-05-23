# frozen_string_literal: true
class VaultThumbnailPathService < Hyrax::ThumbnailPathService
  class << self

    # @param [Work, FileSet] object - to get the thumbnail for
    # @return [String] a path to the thumbnail
    def call(object)
      return default_image if object.try(:thumbnail_id).blank?

      thumb = fetch_thumbnail(object)

      return default_image unless thumb
      return call(thumb) unless thumb.file_set?

      if audio?(thumb) || m4a_file?(thumb)
        audio_thumbnail_path(thumb)
      elsif thumbnail?(thumb)
        thumbnail_path(thumb)
      else
        default_image
      end
    end

    private

    # For now we go back to the ActiveFedora FileSet because Hyrax::FileSet
    # doesn't have the method .parent or .files.first.original_file_name,
    # which we need for audio thumbnails. Eventually this becomes
    # Hyrax.custom_queries.find_parent_work(resource: file_set) in v.3.5
    # https://github.com/samvera/hyrax/blob/main/app/models/hyrax/file_set.rb
    def fetch_thumbnail(object)
      return ActiveFedora::Base.find(object.thumbnail_id) unless Hyrax.config.use_valkyrie?
      return object if object.thumbnail_id == object.id
      Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: object.thumbnail_id)
    rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError
      Rails.logger.error("Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}")
      nil
    end

    def m4a_file?(object)
      if object.is_a? Hyrax::FileSet
        return false unless object.original_file_id.present?
        filename = Hyrax.custom_queries.find_file_metadata_by(id: object.original_file_id).original_filename
        filename.include?("m4a")
      else # is an ActiveFedora FileSet
        object.files.any? ? object.files.first.original_name.include?("m4a") : false
      end
    end

    def audio_thumbnail_path(object)
      parent = object.is_a?(Hyrax::FileSet) ? Hyrax.custom_queries.find_parent_work(resource: object) : object.parent
      return audio_image unless (parent.presence && parent.member_of_collection_ids.any?)
      collection = ActiveFedora::Base.find(parent.member_of_collection_ids.first)
      CollectionThumbnailPathService.call(collection)
    end

  end
end
