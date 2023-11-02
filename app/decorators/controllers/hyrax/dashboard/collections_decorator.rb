require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/dashboard/collections_controller.rb')

# OVERRIDE class from Hyrax v. 3.1.0
Hyrax::Dashboard::CollectionsController.class_eval do

  # Catch deleted collection
  rescue_from Ldp::Gone, ActiveFedora::ObjectNotFoundError, with: :not_found

  # actions: index, create, new, edit, show, update, destroy, permissions, citation
  before_action :authenticate_user!, except: [:index, :copy_permissions]

  load_and_authorize_resource except: [:index, :create, :copy_permissions], instance_name: :collection

  self.membership_service_class = ::SortCollectionMembersByDateService

  # Tenant-specific class overrides
  self.presenter_class = ->() {
    case Account.find_by(tenant: Apartment::Tenant.current).try(:name)
    when "vault"
      VaultCollectionPresenter
    else
      Hyrax::CollectionPresenter
    end
  }

  self.form_class = ->() {
    case Account.find_by(tenant: Apartment::Tenant.current).try(:name)
    when "vault"
      VaultCollectionForm
    else
      Hyrax::Forms::CollectionForm
    end
  }

  # Add .call because presenter_class.is_a? Proc
  def presenter
    @presenter ||= begin
                     presenter_class.call.new(curation_concern, current_ability)
                   end
  end

  # Add .call because form_class.is_a? Proc
  def form
    @form ||= form_class.call.new(@collection, current_ability, repository)
  end

  # Add .call because form_class.is_a? Proc
  def collection_params
    @participants = extract_old_style_permission_attributes(params[:collection])
    form_class.call.model_attributes(params[:collection])
  end

  def not_found
    # Sets alert to display once redirected page has loaded
    flash.alert = "The collection you're looking for may have moved or does not exist. Try searching for it in the search bar."
    redirect_to help_path
    return
  end

  def copy_permissions
    user_email = current_user.email
    Hyrax::InheritCollectionPermissionsJob.perform_later(params[:id], user_email, request.base_url)
    flash_message = 'Updating permissions of collection contents. You will receive an email when the update is finished.'
    redirect_to edit_dashboard_collection_path(params[:id], anchor: session[:current_tab]), notice: flash_message
  end

  def no_copy_permissions
    flash_message = "Collection was successfully updated."
    redirect_to edit_dashboard_collection_path(params[:id], anchor: session[:current_tab]), notice: flash_message
  end

  def inherit_visibility
    respond_to do |format|
      # Params passed in from hyrax/dashboard/collections/_show_actions.html.erb
      user_email = params[:user_email].gsub('-dot-', '.')
      visibility = params[:visibility]
      Hyrax::InheritCollectionVisibilityJob.perform_later(params[:id], user_email, visibility, request.base_url)
      format.js {
        render 'render_ajax_flash_messages.js.erb' # Notify user that job has been enqueued and warn about subcollections
      }
    end
  end

  # Make all works in the collection downloadable or non-downloadable
  def toggle_downloads
    respond_to do |format|
      ToggleDownloadsJob.perform_later(params[:id], params[:user_email], params[:downloadable])
      format.js {
        render 'render_ajax_flash_messages.js.erb' # Notify user that job has been enqueued and warn about subcollections
      }
    end
  end

  def edit
    form
    if request.base_url.include?("vault")
      document = ::SolrDocument.find(params[:id])
      @all_labels = Collection.controlled_properties.each_with_object({}) do |prop, hash|
        labels = document.send("#{prop.to_s}_label")
        values = document.send(prop)

        hash["#{prop.to_s}_label"] = []
        values.each do |val|
          if val.include?("http")
            hash["#{prop.to_s}_label"].push({label: "#{labels[values.index(val)]}", uri: "#{val}" })
          elsif val.present?
            hash["#{prop.to_s}_label"].push({string: "#{labels[values.index(val)]}" })
          end
        end
      end
    end
    # Gets original filename of an uploaded thumbnail. See #update
    if ::SolrDocument.find(@collection.id).thumbnail_path.include? "uploaded_collection_thumbnails" and uploaded_thumbnail?
      @thumbnail_filename = File.basename(uploaded_thumbnail_files.reject { |f| File.basename(f).include? @collection.id }.first)
    end
  end

  def uploaded_thumbnail?
    uploaded_thumbnail_files.any?
  end

  def uploaded_thumbnail_files
    Dir["#{::CollectionThumbnailPathService.upload_dir(@collection)}/*"]
  end

  def extract_controlled_properties
    attributes = {}
    Collection.controlled_properties.each do |prop|
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

  def update
    unless params[:update_collection].nil?
      process_banner_input
      process_logo_input
    end
    process_uploaded_thumbnail(params[:collection][:thumbnail_upload]) if params[:collection][:thumbnail_upload] # Save the image in the proper dimensions to public folder
    if params[:collection][:in_scua]
      params[:collection][:in_scua] = ActiveModel::Type::Boolean.new.cast(params[:collection][:in_scua])
    end
    process_member_changes
    @collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE unless @collection.discoverable?
    # @collection.attributes = controlled_properties
    @collection.attributes = collection_params.merge(clean_controlled_properties(extract_controlled_properties))
    @collection.to_controlled_vocab
    # we don't have to reindex the full graph when updating collection
    @collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
    if @collection.save!
      after_update
    else
      after_update_error
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
      dir_name = ::CollectionThumbnailPathService.upload_dir(@collection)
      saved_file = Rails.root.join(dir_name, uploaded_file.original_filename)
      # Create directory if it doesn't already exist
      unless File.directory?(dir_name)
        FileUtils.mkdir_p(dir_name)
      else # clear contents
      delete_uploaded_thumbnail
      end
      File.open(saved_file, 'wb') do |file|
        file.write(uploaded_file.read)
      end
      image = MiniMagick::Image.open(saved_file)
      # Save two versions of the image: one for homepage feature cards and one for regular thumbnail
      image.resize('500x900').format("jpg").write("#{dir_name}/#{@collection.id}_card.jpg")
      image.resize('150x300').format("jpg").write("#{dir_name}/#{@collection.id}_thumbnail.jpg")
      File.chmod(0664,"#{dir_name}/#{@collection.id}_thumbnail.jpg")
      File.chmod(0664,"#{dir_name}/#{@collection.id}_card.jpg")
    end

  end
end