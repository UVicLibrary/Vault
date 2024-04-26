module Hyrax
  module ControlledVocabularies
    class Provider < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::EDM.provider

      include FastResourceLabelCaching

      # Return a tuple of url & label
      def solrize
        label = full_label || rdf_label.first.to_s
        return [rdf_subject.to_s] if label.blank? || label == rdf_subject.to_s
        [rdf_subject.to_s, { label: "#{label}$#{rdf_subject}" }]
      end

      # Use the rdf_label method from FastResourceLabelCaching
      alias full_label rdf_label
    end
  end
end
