# OVERRIDE Hyrax 4.0
#
# Prevent a file set from being created/attached twice if the job fails
# once, but succeeds on a subsequent try. This can happen when a work
# has many file sets and the connection times out, even though the file
# was eventually attached successfully.
#
module AttachFilesToWorkJobDecorator

  def perform_af(work, uploaded_files, work_attributes)
    validate_files!(uploaded_files)
    depositor = proxy_or_depositor(work)
    user = User.find_by_user_key(depositor)

    work, work_permissions = create_permissions work, depositor
    uploaded_files.each do |uploaded_file|
      next if file_set_has_parent?(uploaded_file)
      attach_work(user, work, work_attributes, work_permissions, uploaded_file)
    end
  end

  def attach_work(user, work, work_attributes, work_permissions, uploaded_file)
    # Do not make a new file set if one already exists and has been added to the file
    # (This may happen if the job failed before and is now retrying)
    if uploaded_file.file_set_uri.blank?
      actor = Hyrax::Actors::FileSetActor.new(FileSet.create, user)
      file_set_attributes = file_set_attrs(work_attributes, uploaded_file)
      metadata = visibility_attributes(work_attributes, file_set_attributes)
      uploaded_file.add_file_set!(actor.file_set)
      actor.file_set.permissions_attributes = work_permissions
      actor.create_metadata(metadata)
      actor.create_content(uploaded_file)
    else
      actor = Hyrax::Actors::FileSetActor.new(file_set_from_uri(uploaded_file.file_set_uri), user)
    end
    begin
      actor.attach_to_work(work, metadata)
      # This is likely a "stack level too deep" error that sometimes happens
      # with works with >200 file sets. Try again...
    rescue SystemStackError
      actor.attach_to_work(work, metadata)
    end
  end

  # @param [Hyrax::UploadedFile]
  def file_set_has_parent?(file)
    file_set_from_uri(file.file_set_uri).try(:parent).present?
  end

  def file_set_from_uri(uri)
    return nil if uri.blank?
    FileSet.find(uri.split('/').last)
  rescue ActiveFedora::ObjectNotFoundError
    nil
  end

end
AttachFilesToWorkJob.prepend(AttachFilesToWorkJobDecorator)