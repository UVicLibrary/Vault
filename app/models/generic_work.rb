class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  # Adds behaviors for hyrax-doi plugin.
  include Hyrax::DOI::DOIBehavior
  # Adds behaviors for DataCite DOIs via hyrax-doi plugin.
  include Hyrax::DOI::DataCiteDOIBehavior
  
  
  property :alternative_title, predicate: ::RDF::Vocab::DC.alternative do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :edition, predicate: ::RDF::Vocab::SCHEMA.bookEdition do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :geographic_coverage, predicate: ::RDF::Vocab::DC.spatial, class_name: Hyrax::ControlledVocabularies::GeographicCoverage
  
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
  
  property :physical_repository, predicate: ::RDF::Vocab::PROV.atLocation, class_name: Hyrax::ControlledVocabularies::PhysicalRepository
  
  property :collection, predicate: ::RDF::Vocab::PROV.Collection do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :provenance, predicate: ::RDF::Vocab::DC.provenance do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :provider, predicate: ::RDF::Vocab::EDM.provider, class_name: Hyrax::ControlledVocabularies::Provider
  
  property :sponsor, predicate: ::RDF::Vocab::SCHEMA.sponsor do |index|
	index.as :stored_searchable, :facetable
  end
  
  property :genre, predicate: ::RDF::Vocab::SCHEMA.genre, class_name: Hyrax::ControlledVocabularies::Genre
  
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
  
  property :year, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#year') do |index|
	index.as :stored_searchable, :facetable
  end
  
  
  include ::Hyrax::BasicMetadata
  
  property :creator, predicate: ::RDF::Vocab::DC11.creator, class_name: Hyrax::ControlledVocabularies::Creator
      
  property :contributor, predicate: ::RDF::Vocab::DC11.contributor, class_name: Hyrax::ControlledVocabularies::Contributor
  
  property :subject, predicate: ::RDF::Vocab::DC11.subject, class_name: Hyrax::ControlledVocabularies::Subject
  
  #include ::Hyrax::BasicMetadata
  include HasRendering
  validates :title, presence: { message: 'Your work must have a title.' }

  
  def rendering_ids
    to_param
  end
  
  
  # This indexer uses IIIF thumbnails:
  self.indexer = GenericWorkIndexer
  #self.human_readable_type = 'Work'
  
  #def date_created=(value)
  #		super
  #		set_value(:year, value)
  #end
  
  id_blank = proc { |attributes| attributes[:id].blank? }
  
  self.controlled_properties += [:creator, :contributor, :physical_repository, :provider, :subject, :geographic_coverage, :genre]
  accepts_nested_attributes_for :creator, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :contributor, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :physical_repository, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :provider, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :subject, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :geographic_coverage, reject_if: id_blank, allow_destroy: true
  accepts_nested_attributes_for :genre, reject_if: id_blank, allow_destroy: true
  
end
