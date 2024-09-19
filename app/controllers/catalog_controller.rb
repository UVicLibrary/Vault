class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightOaiProvider::Controller

  # These before_action filters apply the hydra access controls
  before_action :enforce_show_permissions, only: :show
  # Allow all search options when in read-only mode
  skip_before_action :check_read_only

  def self.uploaded_field
    "system_create_dtsi"
  end

  def self.modified_field
    "system_modified_dtsi"
  end

  rescue_from Blacklight::Exceptions::InvalidRequest do
    render json: { response: 'Bad Request: try a different search', status: 400 }
  end

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.view.gallery.partials = %i[index_header index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.search_builder_class = ::CustomRangeLimitBuilder # Hyrax::CatalogSearchBuilder

    # Show gallery view
    config.view.gallery.partials = %i[index_header index]
    config.view.slideshow.partials = [:index]

    # Because too many times on Samvera tech people raise a problem regarding a failed query to SOLR.
    # Often, it's because they inadvertantly exceeded the character limit of a GET request.
    config.http_method = :post

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: "title_tesim description_tesim creator_tesim keyword_tesim"
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = "tag_sim"

    # solr field configuration for document/show views
    config.index.title_field = "title_tesim"
    config.index.display_type_field = "has_model_ssim"
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display

    # Collection
      config.add_facet_field "member_of_collections_ssim", limit: 10, label: 'Collections'
      config.add_facet_field "genre_label_sim", label: 'Genre', limit: 10
      # Field for blacklight (date) range limit sorting: https://github.com/projectblacklight/blacklight_range_limit
      config.add_facet_field "year_range_isim", label: "Year Range", range: true, include_in_advanced_search: false
      config.add_facet_field "geographic_coverage_label_sim", label: 'Geographic Coverage', limit: 10
      config.add_facet_field "subject_label_sim", label: 'Subject', limit: 5
      config.add_facet_field "language_sim", limit: 5
      config.add_facet_field "creator_label_sim", label: 'Creator', limit: 5
      config.add_facet_field "contributor_label_sim", label: 'Contributor', limit: 5
      config.add_facet_field "fonds_title_sim", label: 'Fonds Title', limit: 5, show: false
      config.add_facet_field "fonds_identifier_sim", label: 'Fonds Identifier', limit: 5, show: false
      config.add_facet_field "has_model_ssim", label: 'Include Model Type', show: false, include_in_advanced_search: false
      config.add_facet_field "physical_repository_label_sim", label: 'Physical Repository', limit: 5
      config.add_facet_field "resource_type_sim", label: 'Resource Type', limit: 5, helper_method: :resource_type_links

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field "alternative_title_tesim", label: "Alternative Title"
    config.add_index_field "tag_tesim", itemprop: 'keywords'
    config.add_index_field "subject_label_tesim", itemprop: 'about', label: "Subject"
    config.add_index_field "creator_label_tesim", itemprop: 'creator', link_to_search: "creator_label_sim", label: "Creator"
    config.add_index_field "contributor_label_tesim", itemprop: 'contributor', label: "Contributor"
    config.add_index_field "publisher_tesim", itemprop: 'publisher'
    config.add_index_field "based_near_label_tesim", itemprop: 'contentLocation'
    config.add_index_field "language_tesim", itemprop: 'inLanguage'
    config.add_index_field "date_uploaded_tesim", itemprop: 'datePublished'
    config.add_index_field "date_modified_tesim", itemprop: 'dateModified'
    config.add_index_field "date_created_tesim", itemprop: 'dateCreated', helper_method: :humanize_date_created
    config.add_index_field "rights_statement_tesim", label: "Rights Statement", helper_method: :rights_statement_links
    config.add_index_field "license_tesim", label: "License"
    config.add_index_field "resource_type_tesim", label: "Resource Type", helper_method: :resource_type_index_links
    config.add_index_field "file_format_tesim", link_to_search: "file_format_sim"
    config.add_index_field "identifier_tesim"
    config.add_index_field "embargo_release_date_dtsi", label: "Embargo release date", helper_method: :human_readable_date
    config.add_index_field "lease_expiration_date_dtsi", label: "Lease expiration date", helper_method: :human_readable_date
    config.add_index_field "extent_tesim"

    #custom index fields
    config.add_index_field "edition_tesim", itemprop: "Edition", label: "Edition"
    config.add_index_field "geographic_coverage_label_tesim", itemprop: "Geographic Coverage", label: "Geographic Coverage"
    config.add_index_field "coordinates_tesim", itemprop: "Coordinates", label: "Coordinates"
    config.add_index_field "chronological_coverage_tesim", itemprop: "Chronological Coverage", label: "Chronological Coverage"
    config.add_index_field "additional_physical_characteristics_tesim", itemprop:"Additional Physical Characteristics", label: "Additional Physical Characteristics"
    config.add_index_field "has_format_tesim", itemprop: "Has Format"
    config.add_index_field "physical_repository_label_tesim", itemprop: "Physical Repository", label: "Physical Repository"
    config.add_index_field "collection_tesim", itemprop: "Collection", label: "Collection"
    config.add_index_field "provenance_tesim", itemprop: "Provenance", label: "Provenance"
    config.add_index_field "provider_label_tesim", itemprop: "Provider", label: "Provider"
    config.add_index_field "sponsor_tesim", itemprop: "Sponsor", label: "Sponsor"
    config.add_index_field "genre_label_tesim", itemprop: "Genre", label: "Genre"
    config.add_index_field "archival_item_identifier_tesim", itemprop:"Archival Item Identifier", label: "Archival Item Identifier"
    config.add_index_field "fonds_title_tesim", itemprop: "Fonds Title", label: "Fonds Title"
    config.add_index_field "fonds_creator_tesim", itemprop: "Fonds Creator", label: "Fonds Creator"
    config.add_index_field "fonds_description_tesim", itemprop: "Fonds Description", label: "Fonds Description"
    config.add_index_field "fonds_identifier_tesim", itemprop: "Fonds Identifier", label: "Fonds Identifier"
    config.add_index_field "is_referenced_by_tesim", itemprop:"Is_referenced_by", label: "Is Referenced By"
    config.add_index_field "date_digitized_tesim", itemprop: "Date Digitized", label: "Date Digitized"
    config.add_index_field "transcript_tesim", itemprop: "Transcript", label: "Transcript"
    config.add_index_field "technical_note_tesim", itemprop: "Technical Note", label: "Technical Note"
    config.add_index_field "year_tesim", itemprop: "Year", label: "Year"
    config.add_index_field "full_text_tsi", label: "Keyword in Context", helper_method: :excerpt_search_term

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field "title_tesim"
    config.add_show_field "description_tesim"
    config.add_show_field "keyword_tesim"
    config.add_show_field "subject_tesim"
    config.add_show_field "creator_tesim"
    config.add_show_field "contributor_tesim"
    config.add_show_field "publisher_tesim"
    config.add_show_field "based_near_label_tesim"
    config.add_show_field "language_tesim"
    config.add_show_field "date_uploaded_tesim"
    config.add_show_field "date_modified_tesim"
    config.add_show_field "date_created_tesim"
    config.add_show_field "rights_statement_tesim", label: "Rights Statement", helper_method: :rights_statement_links
    config.add_show_field "license_tesim"
    config.add_show_field "resource_type_tesim", label: "Resource Type"
    config.add_show_field "format_tesim"
    config.add_show_field "identifier_tesim"
    config.add_show_field "extent_tesim"

    #custom show fields
    config.add_show_field "alternative_title_tesim", label: "Alternative Title"
    config.add_show_field "edition_tesim", label: "Edition"
    config.add_show_field "geographic_coverage_tesim", label: "Geographic Coverage"
    config.add_show_field "coordinates_tesim", label: "Coordinates"
    config.add_show_field "chronological_coverage_tesim", label: "Chronological Coverage"
    config.add_show_field "additional_physical_characteristics_tesim", label:"Additional Physical Characteristics"
    config.add_show_field "has_format_tesim", label: "Has Format"
    config.add_show_field "physical_repository_tesim", label: "Physical Repository"
    config.add_show_field "collection_tesim", label: "Collection"
    config.add_show_field "provenance_tesim", label: "Provenance"
    config.add_show_field "provider_tesim", label: "Provider"
    config.add_show_field "sponsor_tesim", label: "Sponsor"
    config.add_show_field "genre_tesim", label: "Genre"
    config.add_show_field "archival_item_identifier_tesim", label:"Archival Item Identifier"
    config.add_show_field "fonds_title_tesim", label: "Fonds Title"
    config.add_show_field "fonds_creator_tesim", label: "Fonds Creator"
    config.add_show_field "fonds_description_tesim", label: "Fonds Description"
    config.add_show_field "fonds_identifier_tesim", label: "Fonds Identifier"
    config.add_show_field "is_referenced_by_tesim", label:"Is_referenced_by"
    config.add_show_field "date_digitized_tesim", label: "Date Digitized"
    config.add_show_field "transcript_tesim", label: "Transcript"
    config.add_show_field "technical_note_tesim", label: "Technical Note"
    config.add_show_field "year_tesim", label: "Year"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = "title_tesim"
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv full_text_tsi",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor', include_in_advanced_search: false) do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { "spellcheck.dictionary": "contributor" }
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = "contributor_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end


    config.add_search_field('title') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "title"
      }
      solr_name = "title_tesim"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { "spellcheck.dictionary": "creator" }
      solr_name = "creator_tesim"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "subject"
      }
      solr_name = "subject_tesim"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "description"
      }
      solr_name = "description_tesim"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('full text') do |field|
      field.solr_parameters = { "spellcheck.dictionary": "full text" }
      solr_name = "full_text_tsi"
      field.label = "Full text (PDFs-only)"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('publisher', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "publisher"
      }
      solr_name = "publisher_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "date_created"
      }
      solr_name = "date_created_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "language"
      }
      solr_name = "language_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "resource_type"
      }
      solr_name = "resource_type_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "format"
      }
      solr_name ="format_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "identifier"
      }
      solr_name = "identifier_tesim" #solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near_label', include_in_advanced_search: false) do |field|
      field.label = "Location"
      field.solr_parameters = {
        "spellcheck.dictionary": "based_near_label"
      }
      solr_name = "based_near_label_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "keyword"
      }
      solr_name = "keyword_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor', include_in_advanced_search: false) do |field|
      solr_name = "depositor_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement', include_in_advanced_search: false) do |field|
      solr_name = "rights_statement_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license', include_in_advanced_search: false) do |field|
      solr_name = "license_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('extent', include_in_advanced_search: false) do |field|
      solr_name = "extent_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('year range') do |field|
      solr_name = 'year_range_isim'
      field.include_in_simple_select = false
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc", label: "relevance"
    config.add_sort_field "year_sort_dtsi asc, title_sort_ssi asc", label: "date created \u25B2"
    config.add_sort_field "year_sort_dtsi desc, title_sort_ssi desc", label: "date created \u25BC"
    config.add_sort_field "title_sort_ssi asc", label: "title \u25B2"
    config.add_sort_field "title_sort_ssi desc", label: "title \u25BC"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    config.oai = {
        provider: {
            repository_name: Settings.oai.name,
            repository_url: Settings.oai.url,
            record_prefix: Settings.oai.prefix,
            admin_email: Settings.oai.email,
            sample_id: Settings.oai.sample_id
        },
        document: {
            limit: 20000, # number of records returned with each request, default: 15
            set_fields: [ # ability to define ListSets, optional, default: nil
                { label: 'collection', solr_field: 'member_of_collections_ssim' }
            ]
        }
    }

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # This is overridden just to give us a JSON response for debugging.
  def show
    _, @document = fetch params[:id]
    render json: @document.to_h
  end

end
