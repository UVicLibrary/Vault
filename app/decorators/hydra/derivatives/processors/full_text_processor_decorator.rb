# OVERRIDE hydra-derivatives 3.8.0
#   - Increase processing time out for full text extraction
#   - Fall back to local text extraction if Apache Tika extraction fails
#   - Scrub metadata from Apache Tika response
module FullTextProcessorDecorator

  private

  ##
  # Extract full text from the content using Solr's extract handler.
  # This will extract text from the file
  #
  # @return [String] The extracted text
  def extract
    # Normally this uses Apache Tika to run OCR and text extraction
    # on a PDF. But sometimes if there's a lot of text, the job fails with
    # EOFError: End of file reached. We use poppler-utils' pdftotext
    # as a fallback since most PDFs we upload have been OCR'ed and
    # we just need to extract the text.
    text = fetch
    if text.class == Hash
      text["txt_file"].rstrip
    else
      JSON.parse(text)[''].rstrip
    end
  end

  # send the request to the extract service and return the response if it was successful.
  # TODO: this pulls the whole file into memory. We should stream it from Fedora instead
  # @return [String] the result of calling the extract service
  def fetch
    resp = http_request_or_read_locally
    # If this is a string, then the request failed and we used poppler instead
    if resp.class == String
      { "txt_file" => resp } # Return a hash so we can differentiate it from a resp.body
    else
      raise "Solr Extract service was unsuccessful. '#{uri}' returned code #{resp.code} for #{source_path}\n#{resp.body}" unless resp.code == '200'

      file_content.rewind if file_content.respond_to?(:rewind)
      resp.body.force_encoding(resp.type_params['charset']) if resp.type_params['charset']
      scrub_text(resp.body)
    end
  end

  def scrub_text(string)
    regex = /(file:\/\/\/.+?\.txt\s?+)/
    matches = string.scan(regex).flatten.select(&:present?) + string.scan(/\s?+Local Disk/)
    matches.each do |substring|
      string.gsub!(substring, '')
    end
    string
  end

  # Send the request to the extract service
  # @return [Net::HttpResponse] the result of calling the extract service
  def http_request_or_read_locally
    text = read_from_local
    # text over this limit causes connection problems with Solr, which can cause a cascade
    # of failed uploads elsewhere. Assuming any pdf with this many characters has already been
    # OCR'ed, let's just use poppler-utils to convert the pdf into a txt file and return the
    # extracted text.
    return text if text.length > 1000000
    Net::HTTP.start(uri.host, uri.port, use_ssl: check_for_ssl, read_timeout: 2000, open_timeout: 2000) do |http|
      req = Net::HTTP::Post.new(uri.request_uri, request_headers)
      req.basic_auth uri.user, uri.password unless uri.password.nil?
      req.body = file_content
      http.request req
    end
  end

  # Use poppler-utils to extract text from the local file
  # @return [String] The extracted text
  def read_from_local
    if system "pdftocairo -v"
      `pdftotext "#{source_path}" "/tmp/#{File.basename(source_path, '.pdf')}.txt"`
      File.open("/tmp/#{File.basename(source_path, '.pdf')}.txt").read.rstrip
    else
      raise "Poppler utils is not installed"
    end
  end

end

Hydra::Derivatives::Processors::FullText.prepend(FullTextProcessorDecorator)