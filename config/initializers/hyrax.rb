Hyrax.config do |config|
  config.register_curation_concern :generic_work
  # Injected via `rails g hyrax:work Image`
  config.register_curation_concern :image
  # Injected via `rails g hyrax:work IaffWork`
  config.register_curation_concern :iaff_work

  config.iiif_image_server = true

  config.permission_levels = { 'View' => "read",
                               'Download' => "download",
                               'Edit' => "edit" }

  config.permission_options = { 'Choose Access' => "none",
                                'View' => "read",
                                'Download' => "download",
                                'Edit' => "edit" }

  # Email recipient of messages sent via the contact form
  config.contact_email = Settings.contact_email

  # Text prefacing the subject entered in the contact form
  # config.subject_prefix = "Contact form:"

  # How many notifications should be displayed on the dashboard
  # config.max_notifications_for_dashboard = 5

  # How frequently should a file be audited.
  # config.max_days_between_fixity_checks = 7

  # Google Analytics. Note that we hide the work stats page, but we
  # still configure analytics in order to render the gtag that collects
  # data and sends it to the Google Analytics dashboard.
  config.analytics_provider = "ga4"

  # The group name to use for registered users, which CanCan uses to check
  # permissions for the "Institution" visibility option. The default value
  # is "registered" (comes from and is used by Hydra Access Controls). Any user
  # that can sign in is automatically placed in the "registered" group.
  # However, we changed it to "uvic" because there are cases where registered
  # users should not have access to institution-only works and collections.
  config.registered_user_group_name = 'uvic'

  # URL that resolves to an info.json file provided by a IIIF image server
  config.iiif_info_url_builder = ->(_file_id, _base_url) { "#{_base_url}/images/#{ActionDispatch::Journey::Router::Utils.escape_segment(_file_id)}" }

  config.rights_statement_service_class = ->() {
    if Account.find_by(tenant: Apartment::Tenant.current).try(:name).include?("iaff")
      IaffRightsStatementService
    else
      Hyrax::RightsStatementService
    end
  }

  config.iiif_metadata_fields = ->() {
    if Account.find_by(tenant: Apartment::Tenant.current).try(:name).include?("vault")
      [:creator_label, :creator, :contributor_label, :contributor,
       :subject_label, :subject, :publisher, :language, :identifier,
       :keyword, :date_created, :based_near_label, :related_url,
       :resource_type, :source, :rights_statement, :license, :extent,
       :alternative_title, :edition, :geographic_coverage_label,
       :geographic_coverage, :coordinates, :chronological_coverage,
       :additional_physical_characteristics, :has_format, :physical_repository_label,
       :physical_repository, :collection, :provenance, :provider_label, :provider,
       :sponsor, :genre_label, :genre, :format, :archival_item_identifier,
       :fonds_title, :fonds_creator, :fonds_description, :fonds_identifier,
       :is_referenced_by, :date_digitized, :transcript, :technical_note, :year]
    else
      Hyrax::Forms::WorkForm.required_fields
    end
  }

  # Enables a link to the citations page for a generic_file.
  # Default is false
  # config.citations = false

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Specify the form of hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  config.enable_ffmpeg = true

  # Using the database noid minter was too slow when ingesting 1000s of objects (8s per transaction),
  # so switching to UUIDs for the MVP.
  config.enable_noids = false

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Store identifier minter's state in a file for later replayability
  # config.minter_statefile = '/tmp/minter-state'

  # Specify the prefix for Redis keys:
  config.redis_namespace = Settings.redis.default_namespace

  # Specify the path to the file characterization tool:
  config.fits_path = Settings.fits_path

  # Specify the path to the file derivatives creation tool:
  # config.libreoffice_path = "soffice"

  # Stream realtime notifications to users in the browser
  config.realtime_notifications = false

  # Which RDF term should be used to relate objects to an admin set?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:isPartOf) for other relations.
  # config.admin_set_predicate = ::RDF::DC.isPartOf

  # Specify how many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # config.arkivo_api = false

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  config.analytic_start_date = DateTime.new(2020,8,24)

  # Location autocomplete uses geonames to search for named regions.
  # Specify the user for connecting to geonames:
  config.geonames_username = Settings.geonames_username

  # Should the acceptance of the licence agreement be active (checkbox), or
  # implied when the save button is pressed? Set to true for active.
  # The default is true.
  # config.active_deposit_agreement_acceptance = true

  # Should work creation require file upload, or can a work be created first
  # and a file added at a later time?
  # The default is true.
  # config.work_requires_files = true

  # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
  # config.display_share_button_when_not_logged_in = true

  # The user who runs batch jobs. Update this if you aren't using emails
  # config.batch_user_key = 'batchuser@example.com'

  # The user who runs audit jobs. Update this if you aren't using emails
  # config.audit_user_key = 'audituser@example.com'
  #
  # The banner image. Should be 5000px wide by 1000px tall.
  # config.banner_image = 'https://cloud.githubusercontent.com/assets/92044/18370978/88ecac20-75f6-11e6-8399-6536640ef695.jpg'

  # Temporary path to hold uploads before they are ingested into FCrepo.
  # This must be a lambda that returns a Pathname
  if Settings.multitenancy.enabled
   config.upload_path = ->() do
     if Settings.s3.upload_bucket
       "uploads/#{Apartment::Tenant.current}"
     else
       Rails.root + 'tmp' + 'uploads' + Apartment::Tenant.current
     end
   end
  end

  # Location on local file system where derivatives will be stored.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.derivatives_path = File.join(Rails.root, 'tmp', 'derivatives')

  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.working_path = File.join(Rails.root, 'tmp', 'uploads')

  # Specify whether the media display partial should render a download link
  # config.display_media_download_link = true

  # Options to control the file uploader
   config.uploader = {
     limitConcurrentUploads: 6,
     maxNumberOfFiles: 100,
     maxFileSize: 1000.megabytes
   }

  # Fedora import/export tool
  #
  # Path to the Fedora import export tool jar file
  # config.import_export_jar_file_path = "tmp/fcrepo-import-export.jar"
  #
  # Location where Fedora object bags should be exported
  # config.bagit_directory = "tmp/exports"

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  # TODO: Re-enable this when work on BE has been prioritized
  # begin
  #   if defined? BrowseEverything
  #     config.browse_everything = BrowseEverything.config
  #   else
  #     Rails.logger.warn "BrowseEverything is not installed"
  #   end
  # rescue Errno::ENOENT
  #   config.browse_everything = nil
  # end
  config.browse_everything = nil
end
AdminSet::DEFAULT_ID = "admin_set-default"
Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

Qa::Authorities::Local.register_subauthority('subjects', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('languages', 'Qa::Authorities::Local::TableBasedAuthority')
Qa::Authorities::Local.register_subauthority('genres', 'Qa::Authorities::Local::TableBasedAuthority')

##
# @!attribute [rw] sidebar_partials
#   @return [Hash]
#
# @example Add a custom partial to the tasks sidebar block
Hyrax::DashboardController.sidebar_partials[:tasks] += ["hyrax/dashboard/sidebar/batch_processing",
                                                        "hyrax/dashboard/sidebar/replace_or_delete_fast_uris",
                                                        "hyrax/dashboard/sidebar/review_transfers"]

Hyrax::DownloadsController.class_eval do
  skip_before_action :set_locale
end