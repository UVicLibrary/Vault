# Override Hyrax 3.1
Hyrax::WorkFormHelper.module_eval do

  # Add sharing tab
  def form_tabs_for(form:)
    if form.instance_of? Hyrax::Forms::BatchUploadForm
      %w[files metadata relationships share]
    else
      %w[metadata files relationships share]
    end
  end

  # Add "downloadable" checkbox
  # @param form [Hyrax::Forms::WorkForm]
  # @return [Array<String>] the list of names of sections to be rendered in the form_progress panel
  def form_progress_sections_for(*)
    ["downloads"]
  end

  ##
  # Constructs a hash for a form `select`.
  #
  # @param form [Object]
  #
  # @return [Hash{String => String}] a map from file set labels to ids for
  #   the parent object
  # Modified to sort files alphabetically by label/title
  def form_file_set_select_for(parent:)
    return Hash[parent.select_files.sort_by { |k,_| k.downcase }] if parent.respond_to?(:select_files)
    return {} unless parent.respond_to?(:member_ids)

    file_sets =
        Hyrax::PcdmMemberPresenterFactory.new(parent, nil).file_set_presenters

    Hash[file_sets.each_with_object({}) do |presenter, hash|
      hash[presenter.title_or_label] = presenter.id
    end.sort_by { |k,_| k.downcase }]
  end

end