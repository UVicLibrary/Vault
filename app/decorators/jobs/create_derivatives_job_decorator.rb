# OVERRIDE Hyrax 4.0
#   - If the file set is a PDF, resave the parent work so that it
#       indexes the full text. Calling #update_index doesn't work (?),
#       but calling #save does
#   - If the work was created over 3 months ago, export the new file to
#       OLRC for preservation
module CreateDerivativesJobDecorator

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    return if file_set.video? && !Hyrax.config.enable_ffmpeg

    # Ensure a fresh copy of the repo file's latest version is being worked on, if no filepath is directly provided
    filepath = Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory(Hydra::PCDM::File.find(file_id), file_set.id) unless filepath && File.exist?(filepath)

    file_set.create_derivatives(filepath)
    # Reload from Fedora and reindex for thumbnail and extracted text
    file_set.reload
    file_set.update_index
    file_set.parent.save if parent_needs_reindex?(file_set)
    export_new_files(file_set)
  end

  private

  # If this file_set is the thumbnail for the parent work,
  # then the parent also needs to be reindexed.
  def parent_needs_reindex?(file_set)
    return false unless file_set.parent
    # Need to reindex parents of PDF thumbs to index the extracted text
    file_set.parent.thumbnail_id == file_set.id || pdf_with_text?(file_set)
  end

  # If the parent work was created more than 3 months before the file set, export the newly-attached file
  def export_new_files(file_set)
    if file_set.parent.present? && file_set.parent.create_date < 3.months.ago
      BatchExport::ExportFileJob.perform_later(file_set)
    end
  end

  def pdf_with_text?(file_set)
    # When working with Hyrax::FileSet, change fs.pdf? to Hyrax::FileSetTypeService.new(file_set: file_set).pdf?
    file_set.pdf? && file_set.extracted_text.present?
  end

end
CreateDerivativesJob.prepend(CreateDerivativesJobDecorator)