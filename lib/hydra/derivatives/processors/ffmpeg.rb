# An abstract class for asyncronous jobs that transcode files using FFMpeg
module Hydra::Derivatives::Processors
  module Ffmpeg
    extend ActiveSupport::Concern

    INPUT_OPTIONS = :input_options
    OUTPUT_OPTIONS = :output_options

    included do
      include ShellBasedProcessor
    end

    module ClassMethods
      def encode(path, options, output_file)
        inopts = options[INPUT_OPTIONS] ||= "-y"
        outopts = options[OUTPUT_OPTIONS] ||= ""

        # Do nothing for m4a files, which hydra works interprets as 'video/mp4' mime type
        # ffprobe returns the codec_type, which is audio for m4a
        return if (`ffprobe -loglevel error -show_entries stream=codec_type -of csv=p=0 #{path}` == "audio\n") && path.include?(".m4a")

        execute "#{Hydra::Derivatives.ffmpeg_path} #{inopts.gsub('INPUT_PATH', Shellwords.escape(path))} -i #{Shellwords.escape(path)} #{outopts} #{output_file}"
      end
    end
  end
end
