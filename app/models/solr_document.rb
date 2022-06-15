# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument
  include BlacklightOaiProvider::SolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

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

  attribute :extent, Solr::Array, solr_name('extent')
  attribute :rendering_ids, Solr::Array, solr_name('hasFormat', :symbol)

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
      type: 'oai_dc_type_tesim'
  )
  def subject
      fetch(Solrizer.solr_name('subject'), [])
  end
  
  def alternative_title
      fetch(Solrizer.solr_name('alternative_title'), [])
  end
  
  def edition
      fetch(Solrizer.solr_name('edition'), [])
  end
    
  def geographic_coverage
      fetch(Solrizer.solr_name('geographic_coverage'), [])
  end
    
  def coordinates
      fetch(Solrizer.solr_name('coordinates'), [])
  end
    
  def chronological_coverage
    edtf_date('chronological_coverage') # (Solrizer.solr_name('chronological_coverage'), [])
  end
    
  def extent
      fetch(Solrizer.solr_name('extent'), [])
  end
    
  def additional_physical_characteristics
      fetch(Solrizer.solr_name('additional_physical_characteristics'), [])
  end
    
  def has_format
      fetch(Solrizer.solr_name('has_format'), [])
  end
    
  def physical_repository
      fetch(Solrizer.solr_name('physical_repository'), [])
  end
    
  def collection
      fetch(Solrizer.solr_name('collection'), [])
  end
    
  def provenance
      fetch(Solrizer.solr_name('provenance'), [])
  end
    
  def provider
      fetch(Solrizer.solr_name('provider'), [])
  end
    
  def sponsor
      fetch(Solrizer.solr_name('sponsor'), [])
  end
    
  def genre
      fetch(Solrizer.solr_name('genre'), [])
  end
    
  def format
      fetch(Solrizer.solr_name('format'), [])
  end
    
  def archival_item_identifier
      fetch(Solrizer.solr_name('archival_item_identifier'), [])
  end
    
  def fonds_title
      fetch(Solrizer.solr_name('fonds_title'), [])
  end
    
  def fonds_creator
      fetch(Solrizer.solr_name('fonds_creator'), [])
  end
    
  def fonds_description
      fetch(Solrizer.solr_name('fonds_description'), [])
  end
    
  def fonds_identifier
      fetch(Solrizer.solr_name('fonds_identifier'), [])
  end
    
  def is_referenced_by
      fetch(Solrizer.solr_name('is_referenced_by'), [])
  end
    
  def date_digitized
      edtf_date('date_digitized')#fetch(Solrizer.solr_name('date_digitized'), [])
  end
  
  def date_created
      edtf_date('date_created')#fetch(Solrizer.solr_name('date_created'), [])
  end
    
  def transcript
      fetch(Solrizer.solr_name('transcript'), [])
  end
    
  def technical_note
      fetch(Solrizer.solr_name('technical_note'), [])
  end
    
  def year
      fetch(Solrizer.solr_name('year'), [])
  end
  
  def edtf_date(field_name)
    date_string = fetch(Solrizer.solr_name(field_name), [])
    Array(date_string).each_with_object([]) do |date, array|
      array.push(EdtfDateService.new(date).humanized)
    end
  end

  def full_text
    self['full_text_tsi']
  end

end
