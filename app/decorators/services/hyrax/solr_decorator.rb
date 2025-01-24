# frozen_string_literal: true
require_dependency Hyrax::Engine.root.join('app/services/hyrax/solr_service.rb')

# Changed to use the (legacy) standard parser to maintain
# compatibility with Solr versions >= 9.

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::SolrService.class_eval do

  # Wraps rsolr get
  # @return [Hash] the hash straight form rsolr
  def get(query = nil, **args)
    # Make Hyrax.config.solr_select_path the default SOLR path
    solr_path = args.delete(:path) || Hyrax.config.solr_select_path
    args = args.merge(q: query) if query.present?
    # Original was unless query.blank? || use_valkyrie?
    args = args.merge(qt: 'standard') unless query.blank?
    connection.get(solr_path, params: args)
  end

  # Wraps rsolr post
  # @return [Hash] the hash straight form rsolr
  def post(query = nil, **args)
    # Make Hyrax.config.solr_select_path the default SOLR path
    solr_path = args.delete(:path) || Hyrax.config.solr_select_path
    args = args.merge(q: query) if query.present?
    # Original was unless query.blank? || use_valkyrie?
    args = args.merge(qt: 'standard') unless (query.blank? && args[:q].blank?)
    connection.post(solr_path, data: args)
  end

end