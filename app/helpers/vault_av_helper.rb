module VaultAvHelper

  def work_show_page?
    params[:controller].present? && params[:controller].include?("generic_works")
  end

  # Checks to see if a file set-level transcript is available.
  def has_vtt?(file_set)
    File.file? Rails.root.join("public","able_player","transcripts", "#{file_set.id}.vtt")
  end

  def vtt_path_for(file_set)
    "/able_player/transcripts/#{file_set.id}.vtt"
  end

  # file_set is the file set presenter for the video that has a transcript
  def vtt_transcript_for(file_set)
    transcript = file_set.parent.member_presenters.find { |fs| fs.title.first.gsub("transcript","video") == file_set.title.first && fs.pdf?  }
    # Sometimes we have separate vtt files but only one PDF transcript
    if transcript.nil?
      transcript_for(file_set)
    else
      transcript
    end
  end

  def video_files(work_presenter)
    work_presenter.member_presenters.select(&:video?)
  end

  def audio_files(work_presenter)
    work_presenter.member_presenters.select(&:audio?)
  end

  # Checks to see if there is a work-level (parent-level) transcript for multiple files,
  # whereas has_vtt? checks for a file set-level transcript. has_vtt? takes precedence over
  # has_transcript?
  def has_transcript?(file_set)
    SolrDocument.find(file_set.parent.id).full_text.present? && work_show_page?
  end

  def transcript_for(file_set)
    file_set.parent.member_presenters.find { |fs| fs.pdf? && fs.title.first.downcase.include?("transcript") }
  end

  def video_tag_settings(file_set)
    if has_vtt?(file_set)
      sanitize('width="600px"')
    elsif has_transcript?(file_set)
      sanitize('width="600px" data-transcript-text="transcript-text"')
    else
      sanitize('width="750px"')
    end
  end

  def render_track_tag(file_set)
    return "" unless track_source(file_set)
    "<track kind='captions' src='#{track_source(file_set)}' srclang='en' label='English'>".html_safe
  end

  def render_multi_track_tag(file_set)
    return "" unless track_source(file_set)
    ['<span class="able-track" data-kind="captions" data-src="', track_source(file_set),
     '" data-srclang="en" data-label="English"></span>'].join("").html_safe
  end

  def track_source(file_set)
    if has_vtt?(file_set)
      vtt_path_for(file_set)
    elsif has_transcript?(file_set)
      # This is just a dummy to trigger the Hide/Show transcript button, various controls
      # (e.g. dragging, resizing) that aren't available otherwise.
      "/able_player/transcripts/blank.vtt"
    end
  end

end