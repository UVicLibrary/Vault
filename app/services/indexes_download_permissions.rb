# frozen_string_literal: true
module IndexesDownloadPermissions
  extend ActiveSupport::Concern

  def generate_solr_document
    super.tap do |solr_doc|
      # Download permissions are set at the work level,
      # not the file-level. So we need to fetch the parent
      # (if indexing a file set).
      work = parent_for(object)
      if work.present?
        work_permissions = work.permissions.map(&:to_hash)
        solr_doc["download_access_group_ssim"] = download_groups(work_permissions)
        solr_doc["download_access_user_ssim"] = download_users(work_permissions)
      end
    end
  end

  private

  # @return Array[<String>] - list of groups that have permission to download
  def download_groups(permissions)
    accesses = permissions.select { |hash,_| hash[:access] == "download" && hash[:type] == "group" }
    dl_groups = accesses.map { |hash,_| hash[:name] }
    # If object is a work
    #   - index the public group if the download permission level is set to public.
    #   - this doesn't actually affect file download permissions because
    #     those are authorized and checked at the file set level (see below)
    #   - however, this field is used in the query for displaying how many
    #     works will be downloadable when public. So we want to set it anyway,
    #     independent of the visibility
    # If object is a file set
    #   - only index the public group if the file set visibility is also set to public!
    dl_groups -= ["public"] if (object.class.to_s.include?("FileSet") && object.visibility != "open")
    dl_groups.uniq
  end

  # @return Array[<String>] - list of users (email address) that have permission to download
  def download_users(permissions)
    groups = permissions.select { |hash,_| hash[:access] == "download" && hash[:type] == "person" }
    groups.map { |hash,_| hash[:name] }
  end

  def parent_for(object)
    # In Vault, a GenericWork's children can only be file sets
    return object unless object.class.to_s.include? "FileSet"
    case object
    when Hyrax::FileSet
      Hyrax.query_service.find_parents(resource: object).first
    else
      object.parent
    end
  end
end