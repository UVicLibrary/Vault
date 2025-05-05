# OVERRIDE hydra-derivatives v.3.8.0
# Do not generate video derivatives for audio-only m4a files.
# This prevented errors for the Trans Activist Oral Histories collection.

module FfmpegProcessorDecorator

  def encode(path, options, output_file)
    # Do nothing for m4a files, which hydra works interprets as 'video/mp4' mime type
    # ffprobe returns the codec_type, which is audio for m4a
    return if `ffprobe -loglevel error -show_entries stream=codec_type -of csv=p=0 #{path}` == "audio\n"
    super
  end

end
Hydra::Derivatives::Processors::Ffmpeg.prepend(FfmpegProcessorDecorator)