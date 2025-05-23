// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require rails-ujs
//= require popper
//= require twitter/typeahead
//= require bootstrap
//= require jquery.dataTables
//= require dataTables.bootstrap4
//= require turbolinks

// Required by AblePlayer (audio/video player)
//= require js.cookie-2.2.1.min

// Required by Blacklight
//= require blacklight/blacklight
//= require blacklight_advanced_search
//= require blacklight_gallery/default

// Moved the Hyku JS *above* the Hyrax JS to resolve #1187 (following
// a pattern found in ScholarSphere)
//
//= require hyku/groups/per_page
//= require hyku/groups/add_member
//= require vault_homepage
//= require navbar
//= require hyrax
//= require hyrax/editor/mixed_controlled_vocabulary
//= require fast_update
//= require google_map

//= require jquery.flot.pie
//= require flot_graph

// Required for blacklight range limit
//= require bootstrap-slider
//= require blacklight_range_limit/range_limit_distro_facets
//= require blacklight_range_limit/range_limit_shared
//= require blacklight_range_limit/range_limit_slider
//= require tinymce