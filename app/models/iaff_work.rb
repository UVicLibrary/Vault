# Generated via
#  `rails generate hyrax:work IaffWork`
class IaffWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  
  property :provenance, predicate: ::RDF::Vocab::DC.provenance do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :provider, predicate: ::RDF::Vocab::EDM.provider do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :genre, predicate: ::RDF::Vocab::SCHEMA.genre, multiple: false do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :geographic_coverage, predicate: ::RDF::Vocab::DC.spatial do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :coordinates, predicate: ::RDF::Vocab::SCHEMA.geo do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :date_digitized, predicate: ::RDF::Vocab::DC.date, multiple: false do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :technical_note, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#technicalNote') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :gps_or_est, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#gps_or_est'), multiple: false do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :type_of_resource, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false
  
  property :year, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#year')
  
  self.indexer = IaffWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  
    
  property :creator, predicate: ::RDF::Vocab::DC11.creator
  
  property :contributor, predicate: ::RDF::Vocab::DC11.contributor
  
  property :subject, predicate: ::RDF::Vocab::DC11.subject
  
  property :physical_repository, predicate: ::RDF::Vocab::PROV.atLocation
  
  property :provider, predicate: ::RDF::Vocab::EDM.provider
  
  #property :genre, predicate: ::RDF::Vocab::SCHEMA.genre
  

end
