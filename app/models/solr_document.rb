# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior
  # Add attributes for DOIs for hyrax-doi plugin.
  include Hyrax::DOI::SolrDocument::DOIBehavior
  # Add attributes for DataCite DOIs for hyrax-doi plugin.
  include Hyrax::DOI::SolrDocument::DataCiteDOIBehavior

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models.
  use_extension(Hydra::ContentNegotiation)

  attribute :extent, Solr::Array, 'extent_tesim'
  attribute :rendering_ids, Solr::Array, 'hasFormat_ssim'

  # Add controlled vocabulary fields
  # Contributor and Subject are already default fields
  attribute :creator, Solr::Array, "creator_tesim"
  attribute :creator_label, Solr::Array, "creator_label_tesim"
  attribute :contributor_label, Solr::Array, "contributor_label_tesim"
  attribute :subject_label, Solr::Array, "subject_label_tesim"
  attribute :provider, Solr::Array, "provider_tesim"
  attribute :provider_label, Solr::Array, "provider_label_tesim"
  attribute :physical_repository, Solr::Array, "physical_repository_tesim"
  attribute :physical_repository_label, Solr::Array, "physical_repository_label_tesim"
  attribute :geographic_coverage, Solr::Array, "geographic_coverage_tesim"
  attribute :geographic_coverage_label, Solr::Array, "geographic_coverage_label_tesim"
  attribute :genre, Solr::Array, "genre_tesim"
  attribute :genre_label, Solr::Array, "genre_label_tesim"

  # This replaces original_file_id in Hyrax
  attribute :current_file_version, Solr::String, "current_file_version_ssi"

  field_semantics.merge!(
      contributor: 'contributor_label_tesim',
      coverage: 'oai_dc_coverage_tesim',
      creator: 'creator_label_tesim',
      date: 'date_created_tesim',
      description: 'description_tesim',
      format: 'extent_tesim',
      identifier: 'identifier_tesim',
      language: 'language_tesim',
      publisher: 'publisher_tesim',
      relation: 'oai_dc_relation_tesim',
      rights: 'rights_statement_tesim',
      source: 'physical_repository_label_tesim',
      subject: 'subject_label_tesim',
      title: 'title_tesim',
      type: 'oai_dc_type_tesim',
      thumbnail_path: 'thumbnail_path_ss', # These last 2 fields are made available for the OAI <Identifier> tag
      model: 'has_model_ssim'              # in blacklight_oai_provider (for import into Alma/Primo main catalog)
  )

  def subject
      fetch('subject_tesim', [])
  end

  def alternative_title
      fetch('alternative_title_tesim', [])
  end

  def edition
      fetch('edition_tesim', [])
  end

  def geographic_coverage
      fetch('geographic_coverage_tesim', [])
  end

  def coordinates
      fetch('coordinates_tesim', [])
  end

  def chronological_coverage
    fetch('chronological_coverage_tesim',[])
  end

  def extent
      fetch('extent_tesim', [])
  end

  def additional_physical_characteristics
      fetch('additional_physical_characteristics_tesim', [])
  end

  def has_format
      fetch('has_format_tesim', [])
  end

  def physical_repository
      fetch('physical_repository_tesim', [])
  end

  def collection
      fetch('collection_tesim', [])
  end

  def provenance
      fetch('provenance_tesim', [])
  end

  def provider
      fetch('provider_tesim', [])
  end

  def sponsor
      fetch('sponsor_tesim', [])
  end

  def genre
      fetch('genre_tesim', [])
  end

  def format
      fetch('format_tesim', [])
  end

  def archival_item_identifier
      fetch('archival_item_identifier_tesim', [])
  end

  def fonds_title
      fetch('fonds_title_tesim', [])
  end

  def fonds_creator
      fetch('fonds_creator_tesim', [])
  end

  def fonds_description
      fetch('fonds_description_tesim', [])
  end

  def fonds_identifier
      fetch('fonds_identifier_tesim', [])
  end

  def is_referenced_by
      fetch('is_referenced_by_tesim', [])
  end

  def date_digitized
      fetch('date_digitized_tesim',[])
  end

  def date_created
      fetch('date_created_tesim',[])
  end

  def transcript
      fetch('transcript_tesim', [])
  end

  def technical_note
      fetch('technical_note_tesim', [])
  end

  def year
      fetch('year_tesim', [])
  end

  def year_range
    fetch('year_range_isim', [])
  end

  def full_text
      fetch('full_text_tsi', [])
  end

  def in_scua?
      fetch('in_scua_bsi', nil)
  end

  def doi
    fetch('doi_ssi', [])
  end

  # Override methods from Hyrax::SolrDocument::Characterization

  ##
  # @todo this might not be indexed normally. deprecate?
  def filename
    File.basename(self["import_url_ssim"].first) if self['import_url_ssim']
  end

  def last_modified
    self["timestamp"]
  end

end
