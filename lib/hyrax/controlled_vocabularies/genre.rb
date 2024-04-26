module Hyrax
  module ControlledVocabularies
    class Genre < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::SCHEMA.genre

      include GettyAatLabelCaching

      # Return a tuple of url & label
      def solrize
        # Return the URI if there is no label (yet)
        return [rdf_subject.to_s] if (rdf_label.first.to_s.blank? ||
                                      rdf_label.first.to_s == rdf_subject.to_s ||
                                      no_english_label?)
        label = full_label || get_english_label(rdf_label).to_s
        [rdf_subject.to_s, { label: "#{label}$#{rdf_subject}" }]
      end

      private

      def no_english_label?
        rdf_label.map{ |r| r if r.language.match(/en/) }.compact.empty?
      end

      def get_english_label(labels)
        label = labels.find { |label| label if label.language == :en }
        return label if label.present?

        # There may be variant spellings. Use the American English label preferably
        label = labels.find { |label| label if label.language == :"en-us" }
        # Otherwise, use the first available English label
        label.present? ? label : labels.find { |label| label.language.match(/en/) }
      end

    end
  end
end
