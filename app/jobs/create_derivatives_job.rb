class CreateDerivativesJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    return if file_set.video? && !Hyrax.config.enable_ffmpeg
    filename = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    file_set.create_derivatives(filename)
    # Reload from Fedora and reindex for thumbnail and extracted text
    file_set.reload
    file_set.update_index
    file_set.parent.save if parent_needs_reindex?(file_set)
    export_new_files(file_set)
  end

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
