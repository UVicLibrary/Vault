# OVERRIDE hydra-derivatives v.3.8.0
# When creating a video thumbnail, use a keyframe from halfway
# through the video
module VideoProcessorDecorator

  def options_for(format)
    input_options = ""
    output_options = "-s #{size_attributes} #{codecs(format)}"
    if format == "jpg"
      input_options += " -itsoffset -#{halfway(source_path)}"
      output_options += " -vframes 1" # -an -f rawvideo
    else
      input_options += @directives[:input_options] if @directives[:input_options].present?
      output_options += " #{video_attributes} #{audio_attributes}"
    end

    { Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => output_options,
      Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => input_options }
  end

  def halfway(path)
    `ffmpeg -i #{path} 2>&1 | grep Duration | awk '{print $2}' | tr -d , | awk -F ':' '{print ($3+$2*60+$1*3600)/2}'`.gsub("\n","")
  end

end
Hydra::Derivatives::Processors::Video::Processor.prepend(VideoProcessorDecorator)