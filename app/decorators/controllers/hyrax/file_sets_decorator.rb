require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/file_sets_controller.rb')

# OVERRIDE class from Hyrax v. 3.4
Hyrax::FileSetsController.class_eval do

  # Defined in the hydra-head gem
  # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
  include Hydra::Controller::IpBasedAbility


  # This can be deleted after upgrading to Hyrax 3.5 since it's exactly the same
  def initialize_edit_form
    guard_for_workflow_restriction_on!(parent: parent)
    case file_set
    when Hyrax::Resource
      @form = Hyrax::Forms::ResourceForm.for(file_set)
      @form.prepopulate!
    else
      @form = form_class.new(file_set)
      @form[:visibility] = file_set.visibility # workaround for hydra-head < 12
    end
    @version_list = Hyrax::VersionListPresenter.for(file_set: file_set)
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