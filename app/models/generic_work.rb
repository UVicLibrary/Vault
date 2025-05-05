class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  # Adds behaviors for hyrax-doi plugin.
  include Hyrax::DOI::DOIBehavior
  # Adds behaviors for DataCite DOIs via hyrax-doi plugin.
  include Hyrax::DOI::DataCiteDOIBehavior

  # Only define properties specific to file sets here, or to file sets
  # and one other model type. Any property included in all Vault models
  # (collections, works, file sets) goes in app/models/concerns/vault_basic_metadata.
  
  property :edition, predicate: ::RDF::Vocab::SCHEMA.bookEdition do |index|
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

  property :collection, predicate: ::RDF::Vocab::PROV.Collection do |index|
	  index.as :stored_searchable, :facetable
  end
  
  property :provenance, predicate: ::RDF::Vocab::DC.provenance do |index|
	  index.as :stored_searchable, :facetable
  end

  property :sponsor, predicate: ::RDF::Vocab::SCHEMA.sponsor do |index|
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

  property :identifier, predicate: ::RDF::Vocab::DC.identifier

  property :related_url, predicate: ::RDF::RDFS.seeAlso

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

  property :part_of, predicate: ::RDF::Vocab::DC.isPartOf

  # These lines must appear AFTER all custom properties are declared.
  # include ::Hyrax::BasicMetadata
  include ::VaultBasicMetadata


  include HasRendering
  validates :title, presence: { message: 'Your work must have a title.' }

  
  # def rendering_ids
  #   to_param
  # end
  
  # This indexer uses IIIF thumbnails:
  self.indexer = GenericWorkIndexer
  
end
