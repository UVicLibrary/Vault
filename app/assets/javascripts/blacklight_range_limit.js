// Master manifest file for engine, so local app can require
// this one file, but get all our files -- and local app
// require does not need to change if we change file list.

// jquery is already included in application.js, so requiring it a 2nd time here would break things
// require 'jquery'

//= require 'flot/jquery.flot.js'
//= require 'flot/jquery.flot.selection.js'
//= require 'bootstrap-slider'

//= require bootstrap/tooltip

//= require_tree './blacklight_range_limit'
