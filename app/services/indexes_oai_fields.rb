module IndexesOAIFields
  extend ActiveSupport::Concern

  included do
    class_attribute :coverage_field, :type_field, :relation_field
    self.coverage_field = 'oai_dc_coverage_tesim'.freeze
    self.type_field = 'oai_dc_type_tesim'.freeze
    self.relation_field = 'oai_dc_relation_tesim'.freeze
  end

  def generate_solr_document
    super.tap do |solr_doc|
      index_coverage_field(solr_doc)
      index_type_field(solr_doc)
      index_relation_field(solr_doc)
    end
  end

  # dc:coverage = geographic coverage + chronological coverage
  def index_coverage_field(solr_doc)
    if solr_doc['geographic_coverage_label_tesim'] or solr_doc['chronological_coverage_tesim']
      geographic_label = solr_doc['geographic_coverage_label_tesim']
      chronological_label = solr_doc['chronological_coverage_tesim']
      solr_doc[coverage_field] = [geographic_label, chronological_label].reject { |val| val.nil? }.flatten
    end
  end

  # dc:type = human readable label for resource type (e.g. StillImage)
  def index_type_field(solr_doc)
    if resource_type = solr_doc['resource_type_tesim']
      solr_doc[type_field] = resource_type.map { |val| Hyrax::ResourceTypesService.label(val).gsub(' ','') }
    end
  end

  def index_relation_field(solr_doc)
    if object.class == GenericWork
      # dc:relation = title(s) of collection(s)
      if collections = solr_doc['member_of_collections_ssim']
        solr_doc[relation_field] = collections.map { |val| "IsPartOf #{val}" }
      end
    elsif object.class == Hyrax.config.collection_class
      # dc:relation = titles of parent or child collections if any exist
      if object.parent_collections or object.child_collections
        parents = object.parent_collections.map { |c| "IsPartOf #{c.title.first}" }
        children = object.child_collections.map { |c| "HasPart #{c.title.first}" }
        solr_doc['oai_dc_relation_tesim'] = parents + children
      end
    end
  end
end