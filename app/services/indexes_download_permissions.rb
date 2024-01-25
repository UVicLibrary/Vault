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
        permissions = work.permissions.map(&:to_hash)
        solr_doc["download_access_group_ssim"] = download_groups(permissions, work)
        solr_doc["download_access_user_ssim"] = download_users(permissions)
      end
    end
  end

  private

  # @return Array[<String>] - list of groups that have permission to download
  def download_groups(permissions, object)
    accesses = permissions.select { |hash,_| hash[:access] == "download" && hash[:type] == "group" }
    dl_groups = accesses.map { |hash,_| hash[:name] }
    if object.visibility == "open" && object.downloadable
      dl_groups += ["public"]
    end
    dl_groups.uniq
  end

  # @return Array[<String>] - list of users (email address) that have permission to download
  def download_users(permissions)
    groups = permissions.select { |hash,_| hash[:access] == "download" && hash[:type] == "person" }
    groups.map { |hash,_| hash[:name] }
  end

  def parent_for(object)
    return object unless object.class.to_s.include? "FileSet"
    case object
    when Hyrax::FileSet
      Hyrax.query_service.find_parents(resource: object).first
    else
      object.parent
    end
  end
end