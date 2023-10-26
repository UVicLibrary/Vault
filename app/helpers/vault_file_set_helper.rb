module VaultFileSetHelper

  # Override Hyrax::FileSetHelper in Hyrax v. 3.1
  def display_media_download_link?(file_set:)
    if current_account.name.include? "vault"
      # We currently check a work attribute for this with plans
      # to refactor it to can?(:download, ...) only
      can?(:edit, file_set.id) or file_set.parent.downloadable?
    else
      Hyrax.config.display_media_download_link? &&
          can?(:download, file_set)
    end
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
    file_set.parent.member_presenters.select(&:audio?).count > 1
  end

  def multiple_video?(file_set)
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
    return false unless current_account.name.include? "vault"
    pdf = pdf_file_set(presenter)
    pdf.present? && display_media_download_link?(file_set: pdf)
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
    case presenter
    when VaultWorkShowPresenter
      presenter.member_presenters.find { |fs| fs.pdf? }
    when VaultFileSetPresenter
      presenter.parent.member_presenters.find { |fs| fs.pdf? }
    end
  end

  def iiif_image_path(file_set, size)
    # latest_file_id is defined in app/presenters/hyrax/displays_image.rb
    path = file_set.send(:latest_file_id)
    Riiif::Engine.routes.url_helpers.image_path(
        path,
        size: size
    )
  end

  def default_image
    ActionController::Base.helpers.image_path 'work.png'
  end

end