module VaultFileSetHelper

  def work_show_page?
    params[:controller].present? && params[:controller].include?("generic_works")
  end

  # Override Hyrax::FileSetHelper in Hyrax v. 3.1
  def media_display_partial(file_set)
    'hyrax/file_sets/media_display/' +
        if file_set.image?
        # renders base/hyrax/iiif_viewers/_unversal_viewer on a work page
        # and hyrax/file_sets/media_display/image on a file set page
          'image'
        # .m4a files should be categorized as audio
        elsif file_set.audio? || m4a?(file_set)
          if current_account.name.include? "vault"
            'vault/audio'
          else
            'audio'
          end
        elsif file_set.video?
          if current_account.name.include? "vault"
            'vault/video'
          else
            'video'
          end
        elsif file_set.pdf?
          'pdf'
        elsif file_set.office_document?
          'office_document'
        else
          'default'
        end
  end

  def m4a?(file_set)
    file_set.filename.present? && file_set.filename.include?(".m4a")
  end

  def one_image?(presenter)
    presenter.member_presenters.select(&:image?).count == 1
  end

  def multiple_audio?(file_set)
    return false if action_name == "edit"
    file_set.parent.member_presenters.select(&:audio?).count > 1
  end

  def multiple_video?(file_set)
    return false if action_name == "edit"
    file_set.parent.member_presenters.select(&:video?).count > 1
  end

  # CUSTOM METHODS for displaying PDF download links for image or
  # audio/visual works. Use cases: Medieval manuscripts with PDF
  # transcriptions, PDF transcripts of A/V files.
  #
  # NOTE: these methods are only used for app/views/base/hyrax/_universal_viewer.
  # On PDF work show pages, we use #display_media_download_link?

  # @param [VaultFileSetPresenter or VaultWorkShowPresenter]
  def display_pdf_download_link?(presenter)
    pdf = pdf_file_set(presenter)
    pdf.present? && display_media_download_link?(file_set: pdf) && work_show_page?
  end

  # @param [VaultFileSetPresenter]
  def pdf_link_text(file_set)
    if pdf_file_set(file_set)
      t('hyrax.file_set.show.downloadable_content.pdf_link') +
        (pdf_file_set(file_set).title.first.downcase.include?("transcript") ? " transcription" : "")
    end
  end

  # @param [VaultWorkShowPresenter]
  def pdf_file_set(presenter)
    if presenter.class.to_s.include? "Work"
      presenter.member_presenters.find { |fs| fs.pdf? }
    elsif presenter.class.to_s.include? "FileSet"
      presenter.parent.member_presenters.find { |fs| fs.pdf? }
    end
  end

  def iiif_image_path(solr_doc, size)
    path = latest_file_id(solr_doc)
    Riiif::Engine.routes.url_helpers.image_path(
        path,
        size: size
    )
  end

  def latest_file_id(solr_doc)
    solr_doc.try(:current_file_version) || Hyrax::VersioningService.versioned_file_id(FileSet.find(solr_doc.id).original_file)
  end

  def default_image
    ActionController::Base.helpers.image_path 'work.png'
  end

end
