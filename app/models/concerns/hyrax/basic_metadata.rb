module Hyrax
  # An optional model mixin to define some simple properties. This must be mixed
  # after all other properties are defined because no other properties will
  # be defined once  accepts_nested_attributes_for is called
  module BasicMetadata
    extend ActiveSupport::Concern

    included do
      property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

      # Indexed on file set
      property :last_fixity_check, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#last_fixity_check'), multiple: false

      # Used to allow/disallow downloads
      property :downloadable, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#downloadable'), multiple: false

      property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

      property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false

      property :creator, predicate: ::RDF::Vocab::DC11.creator, class_name: Hyrax::ControlledVocabularies::Creator
      property :part_of, predicate: ::RDF::Vocab::DC.isPartOf
      property :resource_type, predicate: ::RDF::Vocab::DC.type
      property :contributor, predicate: ::RDF::Vocab::DC11.contributor
      property :description, predicate: ::RDF::Vocab::DC11.description
      property :keyword, predicate: ::RDF::Vocab::DC11.relation
      # Used for a license
      property :license, predicate: ::RDF::Vocab::DC.rights

      # This is for the rights statement
      property :rights_statement, predicate: ::RDF::Vocab::SCHEMA.license
      property :publisher, predicate: ::RDF::Vocab::DC11.publisher
      property :date_created, predicate: ::RDF::Vocab::DC.created do |index|
        index.as :stored_searchable, :facetable
      end
      property :subject, predicate: ::RDF::Vocab::DC11.subject
      property :language, predicate: ::RDF::Vocab::DC11.language
      property :identifier, predicate: ::RDF::Vocab::DC.identifier
      property :based_near, predicate: ::RDF::Vocab::SCHEMA.spatialCoverage, class_name: Hyrax::ControlledVocabularies::Location
      property :related_url, predicate: ::RDF::RDFS.seeAlso
      property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation
      property :source, predicate: ::RDF::Vocab::DC.source
      

      id_blank = proc { |attributes| attributes[:id].blank? }

      class_attribute :controlled_properties
      self.controlled_properties = [:based_near]
      accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true
    end
    
    def to_controlled_vocab
    	controlled_properties.each do |field|
				if field.to_s == "based_near"
					class_name = "Hyrax::ControlledVocabularies::Location".constantize
				else
					class_name = "Hyrax::ControlledVocabularies::#{field.to_s.camelize}".constantize
				end
				output =  self.send(field.to_s).map do |val| 
					val.include?("http") ? class_name.new(val.strip) : val
				end
				self.send(field.to_s+"=", output)
			end
		end
  end
end