module VaultWorkFormHelper

  def form_tabs_for(form:)
    if form.instance_of? Hyrax::Forms::BatchUploadForm
      %w[files metadata relationships share]
    else
      %w[metadata files relationships share]
    end
  end

  # @param form [Hyrax::Forms::WorkForm]
  # @return [Array<String>] the list of names of sections to be rendered in the form_progress panel
  def form_progress_sections_for(*)
    super + ["downloads"]
  end

end