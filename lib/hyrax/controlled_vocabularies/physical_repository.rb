module Hyrax
  module ControlledVocabularies
    class PhysicalRepository < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::PROV.atLocation

      # Return a tuple of url & label
      def solrize
        return [rdf_subject.to_s] if rdf_label.first.to_s.blank? || rdf_label.first.to_s == rdf_subject.to_s
        [rdf_subject.to_s, { label: "#{rdf_label.first}$#{rdf_subject}" }]
      end
    end
  end
end
