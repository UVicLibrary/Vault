# frozen_string_literal: true
module VaultBasicMetadata
  extend ActiveSupport::Concern

  included do
    # Define/list properties common to all Vault models
    # (Collections, GenericWork, and FileSets) here. This module
    # is intended as a replacement for Hyrax::BasicMetadata, since
    # the Hyrax module has some extra properties that we don't want
    # at this time. We've also added our own custom properties.

    property :alternative_title, predicate: ::RDF::Vocab::DC.alternative do |index|
      index.as :stored_searchable, :facetable
    end

    property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation

    property :date_created, predicate: ::RDF::Vocab::DC.created do |index|
      index.as :stored_searchable, :facetable
    end

    property :description, predicate: ::RDF::Vocab::DC11.description

    property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false

    property :keyword, predicate: ::RDF::Vocab::DC11.relation

    property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

    property :language, predicate: ::RDF::Vocab::DC11.language

    property :license, predicate: ::RDF::Vocab::DC.rights

    property :publisher, predicate: ::RDF::Vocab::DC11.publisher

    property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

    property :resource_type, predicate: ::RDF::Vocab::DC.type

    property :rights_statement, predicate: ::RDF::Vocab::SCHEMA.license

    property :source, predicate: ::RDF::Vocab::DC.source

    property :year, predicate: ::RDF::URI.new('http://library.uvic.ca/ns/uvic#year') do |index|
      index.as :stored_searchable, :facetable
    end

    # Controlled vocabulary fields common to collections, generic works, and file sets.
    # Fields that are both in works and file sets should be put in respective
    # app/models/X files.
    property :based_near, predicate: ::RDF::Vocab::SCHEMA.spatialCoverage, class_name: Hyrax::ControlledVocabularies::Location
    property :contributor, predicate: ::RDF::Vocab::DC11.contributor, class_name: Hyrax::ControlledVocabularies::Contributor
    property :creator, predicate: ::RDF::Vocab::DC11.creator, class_name: Hyrax::ControlledVocabularies::Creator
    property :genre, predicate: ::RDF::Vocab::SCHEMA.genre, class_name: Hyrax::ControlledVocabularies::Genre
    property :geographic_coverage, predicate: ::RDF::Vocab::DC.spatial, class_name: Hyrax::ControlledVocabularies::GeographicCoverage
    property :physical_repository, predicate: ::RDF::Vocab::PROV.atLocation, class_name: Hyrax::ControlledVocabularies::PhysicalRepository
    property :provider, predicate: ::RDF::Vocab::EDM.provider, class_name: Hyrax::ControlledVocabularies::Provider
    property :subject, predicate: ::RDF::Vocab::DC11.subject, class_name: Hyrax::ControlledVocabularies::Subject

    class_attribute :controlled_properties
    self.controlled_properties = [:based_near, :creator, :contributor, :physical_repository, :provider, :subject, :geographic_coverage, :genre]

    id_blank = proc { |attributes| attributes[:id].blank? }

    accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :creator, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :contributor, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :physical_repository, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :provider, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :subject, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :geographic_coverage, reject_if: id_blank, allow_destroy: true
    accepts_nested_attributes_for :genre, reject_if: id_blank, allow_destroy: true

    # Method used in collections, generic_works, and file_sets
    # to convert string URIs (e.g. 'http://id.worldcat.org/fast/1333924')
    # into Hyrax::ControlledVocabularies::XXXXXX objects
    # (where object.id == 'http://id.worldcat.org/fast/1333924')
    def to_controlled_vocab
      controlled_properties.each do |field|
        # model.properties returns an array of arrays where the first
        # element of the nested array is the field name (a String)
        property = self.class.properties.find { |prop| prop.first.to_sym == field }
        class_name = property.last.class_name
        # Convert Strings (URIs) to the proper classes
        values =  self[field].map do |val|
          val.include?("http") ? class_name.new(val.strip) : val
        end
        self.send(field.to_s + "=", values)
      end
    end
  end # included do
end
