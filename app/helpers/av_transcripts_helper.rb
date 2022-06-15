module AvTranscriptsHelper

  # Checks to see if a file set-level transcript is available.
  def has_vtt?(file_set)
    File.file? Rails.root.join("public","able_player","transcripts", "#{file_set.id}.vtt")
  end

  def vtt_path_for(file_set)
    "/able_player/transcripts/#{file_set.id}.vtt"
  end

  # file_set is the file set presenter for the video ()that has a transcript)
  def vtt_transcript_for(file_set)
    file_set.parent.member_presenters.find { |fs| fs.title.first.gsub(" - video","") == "#{file_set.title.first} - transcript"  }
  end

  # Checks to see if there is a work-level (parent-level) transcript for multiple files,
  # whereas has_vtt? checks for a file set-level transcript. has_vtt? takes precedence over
  # has_transcript?
  def parent_has_transcript?(file_set)
    SolrDocument.find(file_set.parent.id).full_text.present? && work_show_page?
  end

  def parent_transcript_for(file_set)
    file_set.parent.member_presenters.find { |fs| fs.pdf? && fs.title.first.downcase.include?("transcript") }
  end

  def work_show_page?
    params[:controller].present? && params[:controller].include?("generic_works")
  end

end