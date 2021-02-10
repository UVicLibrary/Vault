module Hyrax
  module SolrDocument
    module Metadata
      extend ActiveSupport::Concern
      class_methods do
        def attribute(name, type, field)
          define_method name do
            type.coerce(self[field])
          end
        end

        def solr_name(*args)
          Solrizer.solr_name(*args)
        end
      end

      module Solr
        class Array
          # @return [Array]
          def self.coerce(input)
            ::Array.wrap(input)
          end
        end

        class String
          # @return [String]
          def self.coerce(input)
            ::Array.wrap(input).first
          end
        end

        class Date
          # @return [Date]
          def self.coerce(input)
            field = String.coerce(input)
            return if field.blank?
            begin
              ::Date.parse(field)
            rescue ArgumentError
              Rails.logger.info "Unable to parse date: #{field.first.inspect}"
            end
          end
        end
      end

      included do
        attribute :identifier, Solr::Array, solr_name('identifier')
        attribute :creator, Solr::Array, solr_name('creator')
        attribute :creator_label, Solr::Array, solr_name('creator_label')
        attribute :based_near, Solr::Array, solr_name('based_near')
        attribute :based_near_label, Solr::Array, solr_name('based_near_label')
        attribute :related_url, Solr::Array, solr_name('related_url')
        attribute :resource_type, Solr::Array, solr_name('resource_type')
        attribute :edit_groups, Solr::Array, ::Ability.edit_group_field
        attribute :edit_people, Solr::Array, ::Ability.edit_user_field
        attribute :read_groups, Solr::Array, ::Ability.read_group_field
        attribute :collection_ids, Solr::Array, 'collection_ids_tesim'
        attribute :admin_set, Solr::Array, solr_name('admin_set')
        attribute :member_of_collection_ids, Solr::Array, solr_name('member_of_collection_ids', :symbol)
        attribute :description, Solr::Array, solr_name('description')
        attribute :title, Solr::Array, solr_name('title')
        attribute :contributor, Solr::Array, solr_name('contributor')
        attribute :contributor_label, Solr::Array, solr_name('contributor_label')
        attribute :subject, Solr::Array, solr_name('subject')
        attribute :subject_label, Solr::Array, solr_name('subject_label')
        attribute :publisher, Solr::Array, solr_name('publisher')
        attribute :provider, Solr::Array, solr_name('provider')
        attribute :provider_label, Solr::Array, solr_name('provider_label')
        attribute :language, Solr::Array, solr_name('language')
        attribute :keyword, Solr::Array, solr_name('keyword')
        attribute :license, Solr::Array, solr_name('license')
        attribute :source, Solr::Array, solr_name('source')
        attribute :date_created, Solr::Array, solr_name('date_created')
        attribute :rights_statement, Solr::Array, solr_name('rights_statement')
        attribute :physical_repository, Solr::Array, solr_name('physical_repository')
        attribute :physical_repository_label, Solr::Array, solr_name('physical_repository_label')
        attribute :geographic_coverage, Solr::Array, solr_name('geographic_coverage')
        attribute :geographic_coverage_label, Solr::Array, solr_name('geographic_coverage_label')
        attribute :genre, Solr::Array, solr_name('genre')
        attribute :genre_label, Solr::Array, solr_name('genre_label')
        attribute :year, Solr::Array, solr_name('year')
        

        attribute :mime_type, Solr::String, solr_name('mime_type', :stored_sortable)
        attribute :workflow_state, Solr::String, solr_name('workflow_state_name', :symbol)
        attribute :human_readable_type, Solr::String, solr_name('human_readable_type', :stored_searchable)
        attribute :representative_id, Solr::String, solr_name('hasRelatedMediaFragment', :symbol)
        # extract the term name from the rendering_predicate (it might be after the final / or #)
        attribute :rendering_ids, Solr::Array, solr_name(Hyrax.config.rendering_predicate.value.split(/#|\/|,/).last, :symbol)
        attribute :thumbnail_id, Solr::String, solr_name('hasRelatedImage', :symbol)
        attribute :thumbnail_path, Solr::String, CatalogController.blacklight_config.index.thumbnail_field
        attribute :label, Solr::String, solr_name('label')
        attribute :file_format, Solr::String, solr_name('file_format')
        attribute :suppressed?, Solr::String, solr_name('suppressed', Solrizer::Descriptor.new(:boolean, :stored, :indexed))
        attribute :current_file_version, Solr::String, "current_file_version_ssi"
        attribute :date_modified, Solr::Date, solr_name('date_modified', :stored_sortable, type: :date)
        attribute :date_uploaded, Solr::Date, solr_name('date_uploaded', :stored_sortable, type: :date)
        attribute :create_date, Solr::Date, solr_name('system_create', :stored_sortable, type: :date)
        attribute :modified_date, Solr::Date, solr_name('system_modified', :stored_sortable, type: :date)
        attribute :embargo_release_date, Solr::Date, Hydra.config.permissions.embargo.release_date
        attribute :lease_expiration_date, Solr::Date, Hydra.config.permissions.lease.expiration_date
      end
    end
  end
end
