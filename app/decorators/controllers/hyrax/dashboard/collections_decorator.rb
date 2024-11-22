require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/dashboard/collections_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::Dashboard::CollectionsController.class_eval do

  # Catch deleted collection
  rescue_from Ldp::Gone, ActiveFedora::ObjectNotFoundError, with: :not_found

  # actions: index, create, new, edit, show, update, destroy, permissions, citation
  before_action :authenticate_user!, except: [:index, :copy_permissions]

  load_and_authorize_resource except: [:index, :create, :copy_permissions], instance_name: :collection

  self.membership_service_class = ::NestedWorksSearchService

  # Tenant-specific class overrides
  self.presenter_class = ->() {
    if Account.find_by(tenant: Apartment::Tenant.current).try(:name).try(:include?, "vault")
      VaultCollectionPresenter
    else
      Hyrax::CollectionPresenter
    end
  }

  self.form_class = ->() {
    if Account.find_by(tenant: Apartment::Tenant.current).try(:name).try(:include?, "vault")
      VaultCollectionForm
    else
      Hyrax::Forms::CollectionForm
    end
  }

  # A page that asks the user if they want to update member
  # works' permissions with the same permissions they just
  # specified for the collection.
  def confirm_access
    flash[:notice] = t('hyrax.dashboard.my.action.collection_update_success')
  end

  # Add .call because presenter_class.is_a? Proc
  def presenter
    @presenter ||= begin
                     presenter_class.call.new(curation_concern, current_ability)
                   end
  end

  # Add .call because form_class.is_a? Proc
  def form
    @form ||=
        case @collection
        when Valkyrie::Resource
          form = Hyrax::Forms::ResourceForm.for(@collection)
          form.prepopulate!
          form
        else
          form_class.call.new(@collection, current_ability, blacklight_config.repository)
        end
  end

  # Add .call because form_class.is_a? Proc
  def collection_params
    if Hyrax.config.collection_class < ActiveFedora::Base
      @participants = extract_old_style_permission_attributes(params[:collection])
      form_class.call.model_attributes(params[:collection])
    else
      params.permit(collection: {})[:collection]
          .merge(params.permit(:collection_type_gid)
                     .with_defaults(collection_type_gid: default_collection_type_gid))
    end
  end

  def not_found
    # Sets alert to display once redirected page has loaded
    flash.alert = "The collection you're looking for may have moved or does not exist. Try searching for it in the search bar."
    redirect_to help_path
    return
  end

  def inherit_visibility
    respond_to do |format|
      # Params passed in from hyrax/dashboard/collections/_show_actions.html.erb
      user_email = params[:user_email].gsub('-dot-', '.')
      visibility = params[:visibility]
      Hyrax::InheritCollectionVisibilityJob.perform_later(params[:id], user_email, visibility, request.base_url)
      format.js {
        render 'ajax_flash_msg.js.erb' # Notify user that job has been enqueued and warn about subcollections
      }
    end
  end

  # Make all works in the collection downloadable or non-downloadable
  def toggle_downloads
    respond_to do |format|
      ToggleDownloadsJob.perform_later(params[:id], params[:user_email], params[:downloadable])
      format.js {
        render 'ajax_flash_msg.js.erb' # Notify user that job has been enqueued and warn about subcollections
      }
    end
  end

  # Used to display how many works in the collection are downloadable,
  # i.e. X works out of Y total in the collection
  def count_downloadable
    # The number of member works that are downloadable
    @downloadable_count = DownloadableCollectionMembersService.new(scope: self,
                                                                   collection: collection,
                                                                   params: {}).downloadable_work_count
    # This sets @members_count: the total number of works in
    # the collection
    member_works
  end

  def edit
    form
    collection_type
    count_downloadable
    # Gets original filename of an uploaded thumbnail. See #update
    if ::SolrDocument.find(@collection.id).thumbnail_path.include? "uploaded_collection_thumbnails" and uploaded_thumbnail?
      @thumbnail_filename = File.basename(uploaded_thumbnail_files.reject { |f| File.basename(f).include? @collection.id }.first)
    end
  end

  def uploaded_thumbnail?
    uploaded_thumbnail_files.any?
  end

  def uploaded_thumbnail_files
    Dir["#{UploadedCollectionThumbnailPathService.upload_dir(@collection)}/*"]
  end

  def extract_controlled_properties
    attributes = {}
    Hyrax.config.collection_class.controlled_properties.each do |prop|
      attribute_key = "#{prop}_attributes"
      if params[:collection].has_key?(attribute_key)
        if params[:collection].has_key?(attribute_key)
          params[:collection][attribute_key].permit!
          attributes[attribute_key] = params[:collection][attribute_key].to_h
        end
      else
        params
      end
    end
    attributes
  end

  def clean_controlled_properties(attributes)
    qa_attributes = {}
    @collection.controlled_properties.each do |field_symbol|
      field = field_symbol.to_s
      # Do not include deleted attributes
      next unless attributes.keys.include?(field+'_attributes')
      filtered_attributes = attributes[field+'_attributes'].select  { |k,v| v['_destroy'].blank? }
      qa_attributes[field] = filtered_attributes.map { |attr| attr[1]['id'] }
      attributes.delete(field)
      attributes.delete(field+'_attributes')
    end
    qa_attributes
  end

  # Deletes any previous thumbnails. The thumbnail indexer (see services/hyrax/indexes_thumbnails)
  # checks if an uploaded thumbnail exists in the public folder before indexing the thumbnail path.
  def delete_uploaded_thumbnail
    FileUtils.rm_rf(uploaded_thumbnail_files)
    @collection.update_index

    respond_to do |format|
      format.html
      format.js # renders delete_uploaded_thumbnail.js.erb, which updates _current_thumbnail.html.erb
    end
  end

  def process_uploaded_thumbnail(uploaded_file)
    dir_name = UploadedCollectionThumbnailPathService.upload_dir(@collection)
    saved_file = Rails.root.join(dir_name, uploaded_file.original_filename)
    # Create directory if it doesn't already exist
    if File.directory?(dir_name) # clear contents
      delete_uploaded_thumbnail
    else
      FileUtils.mkdir_p(dir_name)
    end
    File.open(saved_file, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    # Use libvips to save two versions of the image: one for homepage feature cards and one for regular thumbnail
    `vips thumbnail #{saved_file} #{dir_name}/#{@collection.id}_card.jpg 500x900`
    `vips thumbnail #{saved_file} #{dir_name}/#{@collection.id}_thumbnail.jpg 150x300`

    File.chmod(0o664,"#{dir_name}/#{@collection.id}_thumbnail.jpg")
    File.chmod(0o664,"#{dir_name}/#{@collection.id}_card.jpg")
  end

  def update_active_fedora_collection
    process_member_changes
    process_branding

    process_uploaded_thumbnail(params[:collection][:thumbnail_upload]) if params[:collection][:thumbnail_upload] # Save the image in the proper dimensions to public folder
    if params[:collection][:in_scua]
      params[:collection][:in_scua] = ActiveModel::Type::Boolean.new.cast(params[:collection][:in_scua])
    end
    return valkyrie_update if @collection.is_a?(Valkyrie::Resource)

    @collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE unless @collection.discoverable?
    # @collection.attributes = controlled_properties
    @collection.attributes = collection_params.merge(clean_controlled_properties(extract_controlled_properties))
    @collection.to_controlled_vocab

    if @collection.update(collection_params.except(:members))
      after_update
    else
      after_update_errors(@collection.errors)
    end
  end

  def after_update
    # If access grants have changed (Note: permission deletion is handled by
    # app/decorators/controllers/hyrax/admin/permission_template_accesses_decorator,
    # and adding a user access grant redirects to decorators/hyrax/admin/permission_templates_decorator)
    if new_permissions.any?
      # Redirect to a confirm access/permissions page that
      # allows users to copy collection permissions to member works
      redirect_to main_app.confirm_collection_access_permission_path(params[:id], referer: update_referer)
    else
      respond_to do |format|
        format.html { redirect_to update_referer, notice: t('hyrax.dashboard.my.action.collection_update_success') }
        format.json { render json: @collection, status: :updated, location: dashboard_collection_path(@collection) }
      end
    end
    end

  def new_permissions
    # Reject blank attributes
    return [] unless params['permission_template']
    params['permission_template']['access_grants_attributes'].values.map(&:to_h).reject { |hash| hash.values.include? "" }
  end

  # Triggers a job for copying collection permissions to member works
  def copy_permissions
    user_email = current_user.email
    Hyrax::InheritCollectionPermissionsJob.perform_later(params[:id], user_email, request.base_url)
    flash_message = 'Updating permissions of collection contents. You will receive an email when the update is finished.'
    redirect_to params[:referer], notice: flash_message
  end
end