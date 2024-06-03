require 'hydra/head' unless defined? Hydra

# Extends/modifies Hydra-Head gem v.11.0.7 (hydra-access-controls v.11.0.7)
# to include a "download" permissions attribute. This is needed to set
# work-level download permissions independent of read permissions. By
# default, Hyrax bundles read and download permissions together.
# (Note: collection-level permissions are handled by
# Hyrax::PermissionsTemplate and Hyrax::PermissionsTemplate::Access.)

# app/models/hydra/access_controls/permission.rb

Hydra::AccessControls::Permission.class_eval do
  def build_access(access)
    raise "Can't build access #{inspect}" unless access
    self.mode = case access
                when 'read'
                  [Hydra::AccessControls::Mode.new(::ACL.Read)]
                when 'edit'
                  [Hydra::AccessControls::Mode.new(::ACL.Write)]
                when 'discover'
                  [Hydra::AccessControls::Mode.new(Hydra::ACL.Discover)]
                when 'download'
                  # app/vocabularies/uvic/acl.rb
                  [Hydra::AccessControls::Mode.new(Uvic::ACL.Download)]
                else
                  raise ArgumentError, "Unknown access #{access.inspect}"
                end
  end
end