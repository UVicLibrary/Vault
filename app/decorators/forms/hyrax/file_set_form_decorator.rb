# OVERRIDE Hyrax 4.0 to add custom Vault metadata fields
# This is the form for the valkyrized file set model, Hyrax::FileSet.
# For the ActiveFedora model, see the FileSetEditForm.
Hyrax::Forms::FileSetForm.class_eval do

  include Hyrax::FormFields(:vault_basic_metadata)
  # see config/metadata/file_set_metadata.yml for file set-specific fields

end