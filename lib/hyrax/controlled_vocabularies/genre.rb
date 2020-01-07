module Hyrax
  module ControlledVocabularies
    class Genre < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::SCHEMA.genre

      # Return a tuple of url & label
      def solrize
        return [rdf_subject.to_s] if rdf_label.first.to_s.blank? || rdf_label.first.to_s == rdf_subject.to_s || rdf_label.map{|r| r if r.language==:en}.compact.empty?
        [rdf_subject.to_s, { label: "#{rdf_label.map{|r| r if r.language==:en}.compact.first}$#{rdf_subject}" }]
      end
    end
  end
end
