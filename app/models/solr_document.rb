# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

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
      fetch(Solrizer.solr_name('chronological_coverage'), [])
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
    dc = fetch(Solrizer.solr_name(field_name), [])
    humanized = []
    Array(dc).each do |date|
      if Date.edtf(date.gsub("X", "u")).nil?
        humanized << date + " (unable to parse)"
        next
      end
      humanized << Date.edtf(date.gsub("X", "u")).humanize
    end
    humanized
  end
  
end
