module FullTextHelper

  # Search a solr field for a substring and then show the surrounding words
  def excerpt_search_term(options={})
    search_term = @current_search_session['query_params']['q']
    if search_term.nil? # No search term, show the first 3 rows
      truncated_text(options[:value].first)
    else
      results = find_word(options[:value].first, search_term)
      if results.any?
        highlight(results.join('<br/>'), search_term, highlighter: '<strong>\1</strong>')
      else
        truncated_text(options[:value].first)
      end
    end
  end

  private

  # Find word and show surrounding words
  # Returns an array of strings, e.g.  ["...The hookers and the hustlers...",
  # "...with drug dealers and hustlers...", "...were hustlers..."]
  def find_word(string, search_term)
    r1 = /\w+\W/
    r2 = /\W\w+/
    # Only show first 10 results
    string.scan(/(#{r1}{0,7}#{search_term}s?#{r2}{0,7})/i)[0...10].map { |r| "..." + r.first + "..." }
  end

  def truncated_text(string)
    string.strip.truncate(275)
  end

end