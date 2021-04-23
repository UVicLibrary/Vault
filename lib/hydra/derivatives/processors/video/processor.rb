module Hydra::Derivatives::Processors
  module Video
    class Processor < Hydra::Derivatives::Processors::Processor
      include Ffmpeg

      class_attribute :config
      self.config = Config.new

      protected

      def options_for(format)
        input_options = ""
        output_options = "-s #{config.size_attributes} #{codecs(format)}"

        if format == "jpg"
          # Use a frame that is halfway through the video regardless of the video duration
          input_options +=  "-ss `ffmpeg -i INPUT_PATH 2>&1 | grep Duration | awk '{print $2}' | tr -d , | awk -F ':' '{print ($3+$2*60+$1*3600)/2}'`" # " -itsoffset -2"
          output_options += " -vframes 1 -an -f rawvideo"
        else
          output_options += " #{config.video_attributes} #{config.audio_attributes}"
        end

        { Ffmpeg::OUTPUT_OPTIONS => output_options, Ffmpeg::INPUT_OPTIONS => input_options }
      end

      def codecs(format)
        case format
        when 'mp4'
          config.mpeg4.codec
        when 'webm'
          config.webm.codec
        when "mkv"
          config.mkv.codec
        when "jpg"
          config.jpeg.codec
        else
          raise ArgumentError, "Unknown format `#{format}'"
        end
      end
    end
  end
end
