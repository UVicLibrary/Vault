require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/file_sets_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::FileSetsController.class_eval do
  # include AuthorizeByIpAddress

  # Defined in the hydra-head gem
  # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
  include Hydra::Controller::IpBasedAbility

  self.form_class = Hyrax::FileSetForm

  def initialize_edit_form
    @form = self.form_class.new(curation_concern)
    @parent = @file_set.in_objects.first
    guard_for_workflow_restriction_on!(parent: @parent)
    original = @file_set.original_file
    @version_list = Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
    @groups = current_user.groups
  end

  def show_presenter
    # Tenant-specific file set presenters
    if Settings.multitenancy.enabled
      if current_account.cname.include? "vault"
        VaultFileSetPresenter
      elsif current_account.cname.include? "iaff"
        Hyrax::FileSetPresenter
      end
    else
      VaultFileSetPresenter
    end
  end
end