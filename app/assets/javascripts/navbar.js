$(document).on('turbolinks:load', function() {
    $('#search-top-navbar-collapse').on('shown.bs.collapse', function () {
            $('#search-field-header').focus();
    });

    // Autocomplete for collection titles
    $.getJSON('/browse_collections/autocomplete', function(data) {
      response = JSON.parse(JSON.stringify(data));
        // instantiate the bloodhound suggestion engine
        var collections  = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            local: response
        });
        $('#search-field-header').typeahead({
        minLength: 3,
        hint: false
        }, {
            displayKey: 'title',
            source: collections,
            templates: {
              suggestion: function(data) {
                  return '<a id="' + data.id + '" role="option" href="' + data.link + '">' + data.title + '</a>'
              }
          }
        });
        // Modifications for accessibility. Adapted from:
        // https://www.w3.org/TR/wai-aria-practices-1.2/examples/combobox/combobox-autocomplete-both.html
        $('.tt-dataset').attr('role','listbox');
        $('.tt-dataset-title-search').attr('aria-label','database title').attr('id','title-search-listbox');
        // Custom typeahead events:
        // https://github.com/twitter/typeahead.js/blob/master/doc/jquery_typeahead.md#custom-events
        $('.typeahead').bind('typeahead:render', function() {
            $(this).attr('aria-expanded', true);
        });
        $('.typeahead').bind('typeahead:close', function() {
            $(this).attr('aria-expanded', false);
        });
        $('.typeahead').bind('typeahead:cursorchange', function(e, suggestion) {
            $('.expanded-search-container a[role=option]').removeAttr('aria-selected aria-activedescendant');
            selected = $(document.getElementById(suggestion['id']));
            selected.attr('aria-selected', true);
            selected.attr('aria-activedescendant', suggestion['id']);
        });
    });

});