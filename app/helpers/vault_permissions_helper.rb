module VaultPermissionsHelper
  def collection_permissions(collection)
    controller.can?(:edit, collection) || collection.visibility != "open" ? true : false
  end

  def work_permissions(work)
    controller.can?(:edit, work) || work.visibility != 'open' ? true : false
  end

  def file_set_permissions(fileset)
    controller.can?(:edit, fileset) || fileset.visibility != 'open' ? true : false
  end
end