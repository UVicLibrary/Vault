require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/file_sets_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::FileSetsController.class_eval do
  include AuthorizeByIpAddress

  self.form_class = Hyrax::FileSetForm

  def initialize_edit_form
    @form = self.form_class.new(curation_concern)
    @parent = @file_set.in_objects.first
    guard_for_workflow_restriction_on!(parent: @parent)
    original = @file_set.original_file
    @version_list = Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
    @groups = current_user.groups
  end

  def presenter
    @presenter ||= begin
                     # We can't use #curation_concern_document because the search results
                     # would normally exclude institution-only documents for public users
                     document = ::SolrDocument.find(params[:id])
                     authorize_by_ip(document)
                     presenter = show_presenter.new(document, current_ability, request)
                     raise WorkflowAuthorizationException if presenter.parent.blank?
                     presenter
                   end
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