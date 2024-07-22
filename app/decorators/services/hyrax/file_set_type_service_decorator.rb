# frozen_string_literal: true
#
# Override Hyrax v.3.5 - add detection for pdf and video file types.
# This is needed for CollectionThumbnailPathService and VaultThumbnailPathService.
Hyrax::FileSetTypeService.class_eval do

  DEFAULT_PDF_TYPES = ['application/pdf'].freeze
  DEFAULT_VIDEO_TYPES = ["video/mpeg", "video/mp4", "video/webm", "video/x-msvideo", "video/avi", "video/quicktime", "application/mxf"].freeze

  def pdf?
    pdf_types.include?(mime_type)
  end

  def video?
    video_types.include?(mime_type)
  end

  private

  def pdf_types
    return ::FileSet.pdf_mime_types if defined?(::FileSet)
    DEFAULT_PDF_TYPES
  end

  def video_types
    return ::FileSet.video_mime_types if defined?(::FileSet)
    DEFAULT_VIDEO_TYPES
  end

end