module Hyrax
  module DOI
    module TombstoneHelper

      # @param[<Hash>] DOI metadata fetched from DataCite
      # Citation format is loosely based on Chicago/MLA
      def build_citation(metadata)
        authors = format_authors(normalize_values(metadata['creators'], 'creator'))

        title = metadata['titles'].values.first
        publisher = metadata['publisher']
        pub_date = metadata['publicationYear']

        "#{(authors + ". ") if authors}<em>#{title}</em>. #{publisher}, #{pub_date}, doi: https://doi.org/#{params[:doi]}.".html_safe
      end

      private

      def format_authors(names)
        return nil if names.empty?
        authors = names.map { |name| format_personal_name(name) }
        authors.count >= 3 ? "#{authors.first}, et al" : authors.to_sentence
      end

      # FAST URIs are set up differently than string values, so we normalize the
      # labels/strings before making the citation
      # @param [Hash] - For a URI: 'creator' => [{ 'creatorName' => { '__content__' => 'Label' } }]
      #                 For a String: { 'creatorName' => { '__content__' =" 'String value' } }
      #                 For a placeholder value: { 'creatorName' => ':Unav' }
      # @param [String] - the lowercase field name, e.g. 'creator'
      def normalize_values(hash, field_key)
        return [] unless hash.present?

        values = Array.wrap(hash[field_key]).flatten.map do |value|
          value["#{field_key}Name"].is_a?(Hash) ? value["#{field_key}Name"]["__content__"] : value["#{field_key}Name"]
        end
        values.all? { |value| value.downcase == ":unav" } ? [] : values
      end

      # FAST URI labels for persons often contain dates (e.g. Snow, Edgar, 1905-1972),
      # so we remove them when making citations
      def format_personal_name(name)
        name.match?(/(.*?, .+)/) ? name.match(/(.*?, .+)/)[1].gsub(/, \d+-\d+/,'') : name
      end

    end
  end
end