class ConvertWorkDownloadPermissionsJob < ActiveJob::Base

  def perform(work)
    if work.visibility == "open" && work.downloadable
      permissions_hash = work.permissions.map(&:to_hash)
      return if permissions_hash.include?(name: "public", type: "group", access: "download")
      permissions_hash.push(name: "public", type: "group", access: "download")
      work.permissions = []
      work.permissions_attributes = permissions_hash
      work.save!
    end
  end

end