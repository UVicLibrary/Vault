$(document).on('turbolinks:load', function() {
    $('#search-top-navbar-collapse').on('shown.bs.collapse', function () {
            $('#search-field-header').focus();
    });
});