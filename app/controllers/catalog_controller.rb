class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightOaiProvider::Controller

  # These before_action filters apply the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'

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
    config.tag_cloud_field_name = Solrizer.solr_name("tag", :facetable)

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display

    # Collection
      config.add_facet_field solr_name('member_of_collections', :symbol), limit: 10, label: 'Collections'
      config.add_facet_field solr_name('genre_label', :facetable), label: 'Genre', limit: 10
      config.add_facet_field solr_name("resource_type", :facetable), label: 'Resource Type', limit: 5, helper_method: :resource_type_links
      config.add_facet_field 'year_sort_dtsim', label: 'Year', limit: 10, sort: 'index', helper_method: :render_year_sort # http://jessiekeck.com/customizing-blacklight/facets/
      # Field for blacklight (date) range limit sorting: https://github.com/projectblacklight/blacklight_range_limit
      config.add_facet_field "year_range_isim", label: "Year Range", range: true, include_in_advanced_search: false
      config.add_facet_field solr_name("geographic_coverage_label", :facetable), label: 'Geographic Coverage', limit: 10
      config.add_facet_field solr_name("subject_label", :facetable), label: 'Subject', limit: 10
      config.add_facet_field solr_name("language", :facetable), limit: 5
      config.add_facet_field solr_name("creator_label", :facetable), label: 'Creator', limit: 5
      config.add_facet_field solr_name("contributor_label", :facetable), label: 'Contributor', limit: 5
      config.add_facet_field solr_name("fonds_title", :facetable), label: 'Fonds Title', limit: 5, show: false
      config.add_facet_field solr_name("fonds_identifier", :facetable), label: 'Fonds Identifier', limit: 5, show: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("alternative_title", :stored_searchable), label: "Alternative Title"
    config.add_index_field solr_name("tag", :stored_searchable), itemprop: 'keywords'
    config.add_index_field solr_name("subject_label", :stored_searchable), itemprop: 'about', label: "Subject"
    config.add_index_field solr_name("creator_label", :stored_searchable), itemprop: 'creator', link_to_search: solr_name("creator_label", :facetable), label: "Creator"
    config.add_index_field solr_name("contributor_label", :stored_searchable), itemprop: 'contributor', label: "Contributor"
    config.add_index_field solr_name("publisher", :stored_searchable), itemprop: 'publisher'
    config.add_index_field solr_name("based_near_label", :stored_searchable), itemprop: 'contentLocation'
    config.add_index_field solr_name("language", :stored_searchable), itemprop: 'inLanguage'
    config.add_index_field solr_name("date_uploaded", :stored_searchable), itemprop: 'datePublished'
    config.add_index_field solr_name("date_modified", :stored_searchable), itemprop: 'dateModified'
    config.add_index_field solr_name("date_created", :stored_searchable), itemprop: 'dateCreated', helper_method: :humanize_date_created
    config.add_index_field solr_name("rights_statement", :stored_searchable), label: "Rights Statement", helper_method: :rights_statement_links
    config.add_index_field solr_name("license", :stored_searchable), label: "License"
    config.add_index_field solr_name("resource_type", :stored_searchable), label: "Resource Type", helper_method: :resource_type_index_links
    config.add_index_field solr_name("file_format", :stored_searchable), link_to_search: solr_name("file_format", :facetable)
    config.add_index_field solr_name("identifier", :stored_searchable)
    config.add_index_field solr_name("embargo_release_date", :stored_sortable, type: :date), label: "Embargo release date", helper_method: :human_readable_date
    config.add_index_field solr_name("lease_expiration_date", :stored_sortable, type: :date), label: "Lease expiration date", helper_method: :human_readable_date
    config.add_index_field solr_name('extent', :stored_searchable)

    #custom index fields
    config.add_index_field solr_name("edition", :stored_searchable), itemprop: "Edition", label: "Edition"
    config.add_index_field solr_name("geographic_coverage_label", :stored_searchable), itemprop: "Geographic Coverage", label: "Geographic Coverage"
    config.add_index_field solr_name("coordinates", :stored_searchable), itemprop: "Coordinates", label: "Coordinates"
    config.add_index_field solr_name("chronological_coverage", :stored_searchable), itemprop: "Chronological Coverage", label: "Chronological Coverage"
    config.add_index_field solr_name("additional_physical_characteristics", :stored_searchable), itemprop:"Additional Physical Characteristics", label: "Additional Physical Characteristics"
    config.add_index_field solr_name("has_format", :stored_searchable), itemprop: "Has Format"
    config.add_index_field solr_name("physical_repository_label", :stored_searchable), itemprop: "Physical Repository", label: "Physical Repository"
    config.add_index_field solr_name("collection", :stored_searchable), itemprop: "Collection", label: "Collection"
    config.add_index_field solr_name("provenance", :stored_searchable), itemprop: "Provenance", label: "Provenance"
    config.add_index_field solr_name("provider_label", :stored_searchable), itemprop: "Provider", label: "Provider"
    config.add_index_field solr_name("sponsor", :stored_searchable), itemprop: "Sponsor", label: "Sponsor"
    config.add_index_field solr_name("genre_label", :stored_searchable), itemprop: "Genre", label: "Genre"
    config.add_index_field solr_name("archival_item_identifier", :stored_searchable), itemprop:"Archival Item Identifier", label: "Archival Item Identifier"
    config.add_index_field solr_name("fonds_title", :stored_searchable), itemprop: "Fonds Title", label: "Fonds Title"
    config.add_index_field solr_name("fonds_creator", :stored_searchable), itemprop: "Fonds Creator", label: "Fonds Creator"
    config.add_index_field solr_name("fonds_description", :stored_searchable), itemprop: "Fonds Description", label: "Fonds Description"
    config.add_index_field solr_name("fonds_identifier", :stored_searchable), itemprop: "Fonds Identifier", label: "Fonds Identifier"
    config.add_index_field solr_name("is_referenced_by", :stored_searchable), itemprop:"Is_referenced_by", label: "Is Referenced By"
    config.add_index_field solr_name("date_digitized", :stored_searchable), itemprop: "Date Digitized", label: "Date Digitized"
    config.add_index_field solr_name("transcript", :stored_searchable), itemprop: "Transcript", label: "Transcript"
    config.add_index_field solr_name("technical_note", :stored_searchable), itemprop: "Technical Note", label: "Technical Note"
    config.add_index_field solr_name("year", :stored_searchable), itemprop: "Year", label: "Year"
    config.add_index_field "full_text_tsi", label: "Keyword in Context", helper_method: :excerpt_search_term

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("title", :stored_searchable)
    config.add_show_field solr_name("description", :stored_searchable)
    config.add_show_field solr_name("keyword", :stored_searchable)
    config.add_show_field solr_name("subject", :stored_searchable)
    config.add_show_field solr_name("creator", :stored_searchable)
    config.add_show_field solr_name("contributor", :stored_searchable)
    config.add_show_field solr_name("publisher", :stored_searchable)
    config.add_show_field solr_name("based_near_label", :stored_searchable)
    config.add_show_field solr_name("language", :stored_searchable)
    config.add_show_field solr_name("date_uploaded", :stored_searchable)
    config.add_show_field solr_name("date_modified", :stored_searchable)
    config.add_show_field solr_name("date_created", :stored_searchable)
    config.add_show_field solr_name("rights_statement", :stored_searchable), label: "Rights Statement", helper_method: :rights_statement_links
    config.add_show_field solr_name("license", :stored_searchable)
    config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("format", :stored_searchable)
    config.add_show_field solr_name("identifier", :stored_searchable)
    config.add_show_field solr_name('extent', :stored_searchable)

    #custom show fields
    config.add_show_field solr_name("alternative_title", :stored_searchable), label: "Alternative Title"
    config.add_show_field solr_name("edition", :stored_searchable), label: "Edition"
    config.add_show_field solr_name("geographic_coverage", :stored_searchable), label: "Geographic Coverage"
    config.add_show_field solr_name("coordinates", :stored_searchable), label: "Coordinates"
    config.add_show_field solr_name("chronological_coverage", :stored_searchable), label: "Chronological Coverage"
    config.add_show_field solr_name("additional_physical_characteristics", :stored_searchable), label:"Additional Physical Characteristics"
    config.add_show_field solr_name("has_format", :stored_searchable), label: "Has Format"
    config.add_show_field solr_name("physical_repository", :stored_searchable), label: "Physical Repository"
    config.add_show_field solr_name("collection", :stored_searchable), label: "Collection"
    config.add_show_field solr_name("provenance", :stored_searchable), label: "Provenance"
    config.add_show_field solr_name("provider", :stored_searchable), label: "Provider"
    config.add_show_field solr_name("sponsor", :stored_searchable), label: "Sponsor"
    config.add_show_field solr_name("genre", :stored_searchable), label: "Genre"
    config.add_show_field solr_name("archival_item_identifier", :stored_searchable), label:"Archival Item Identifier"
    config.add_show_field solr_name("fonds_title", :stored_searchable), label: "Fonds Title"
    config.add_show_field solr_name("fonds_creator", :stored_searchable), label: "Fonds Creator"
    config.add_show_field solr_name("fonds_description", :stored_searchable), label: "Fonds Description"
    config.add_show_field solr_name("fonds_identifier", :stored_searchable), label: "Fonds Identifier"
    config.add_show_field solr_name("is_referenced_by", :stored_searchable), label:"Is_referenced_by"
    config.add_show_field solr_name("date_digitized", :stored_searchable), label: "Date Digitized"
    config.add_show_field solr_name("transcript", :stored_searchable), label: "Transcript"
    config.add_show_field solr_name("technical_note", :stored_searchable), label: "Technical Note"
    config.add_show_field solr_name("year", :stored_searchable), label: "Year"

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
      title_name = solr_name("title", :stored_searchable)
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
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end


    config.add_search_field('title') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "title"
      }
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { "spellcheck.dictionary": "creator" }
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "subject"
      }
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.solr_parameters = {
          "spellcheck.dictionary": "description"
      }
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('full text') do |field|
      field.solr_parameters = { "spellcheck.dictionary": "full text" }
      solr_name = "full_text_tsi"
      field.label = "Full text (PDFs only)"
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('publisher', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "publisher"
      }
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "date_created"
      }
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "language"
      }
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "resource_type"
      }
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "format"
      }
      solr_name = solr_name("format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "identifier"
      }
      solr_name = solr_name("id", :stored_searchable)
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
      solr_name = solr_name("based_near_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword', include_in_advanced_search: false) do |field|
      field.solr_parameters = {
        "spellcheck.dictionary": "keyword"
      }
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor', include_in_advanced_search: false) do |field|
      solr_name = solr_name("depositor", :stored_searchable)
      field.include_in_advanced_search = false
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement', include_in_advanced_search: false) do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license', include_in_advanced_search: false) do |field|
      solr_name = solr_name("license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('extent', include_in_advanced_search: false) do |field|
      solr_name = solr_name("extent", :stored_searchable)
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
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
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
