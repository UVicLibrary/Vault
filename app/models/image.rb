# Generated via
#  `rails generate hyrax:work Image`
class Image < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include HasRendering

  property :extent, predicate: ::RDF::Vocab::DC.extent, multiple: true do |index|
    index.as :stored_searchable
  end

  # This must come after the properties because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ImageIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  
   property :alternative_title, predicate: ::RDF::Vocab::DC.alternative do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :edition, predicate: ::RDF::Vocab::SCHEMA.bookEdition do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :geographic_coverage, predicate: ::RDF::Vocab::DC.spatial do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :coordinates, predicate: ::RDF::Vocab::SCHEMA.geo do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :chronological_coverage, predicate: ::RDF::Vocab::DC.temporal do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :extent, predicate: ::RDF::Vocab::DC.extent do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :additional_physical_characteristics, predicate: ::RDF::Vocab::SCHEMA.description do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :has_format, predicate: ::RDF::Vocab::DC.hasFormat do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :physical_repository, predicate: ::RDF::Vocab::PROV.atLocation do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :collection, predicate: ::RDF::Vocab::PROV.Collection do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :provenance, predicate: ::RDF::Vocab::DC.provenance do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :provider, predicate: ::RDF::Vocab::EDM.provider do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :sponsor, predicate: ::RDF::Vocab::SCHEMA.sponsor do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :genre, predicate: ::RDF::Vocab::SCHEMA.genre do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :format, predicate: ::RDF::Vocab::DC.format do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :archival_item_identifier, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#archivalItemIdentifier') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :fonds_title, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#fondsTitle') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :fonds_creator, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#fondsCreator') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :fonds_description, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#fondsDescription') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :fonds_identifier, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#fondsIdentifier') do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :is_referenced_by, predicate: ::RDF::Vocab::DC.isReferencedBy do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :date_digitized, predicate: ::RDF::Vocab::DC.date do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :transcript, predicate: ::RDF::Vocab::SCHEMA.transcript do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :technical_note, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#technicalNote') do |index|
	index.as :stored_searchable, :facetable
  end

  validates :title, presence: { message: 'Your work must have a title.' }

  self.human_readable_type = 'Image'
end
