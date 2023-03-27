var LinkedData = require('hyrax/autocomplete/linked_data');
var Resource = require('hyrax/autocomplete/resource');
var ControlledVocabulary = require('hyrax/editor/controlled_vocabulary');
var Handlebars = require('handlebars');
var ConfirmRemoveDialog = require('hyrax/relationships/confirm_remove_dialog');


$(document).on('turbolinks:load', function() {
    new FastUpdateFormManager($('#new_fast_update_change'));
    new FastUpdateFieldManager($('.form-group.fast_update_change_new_uris'), 'fast_update_change')
});

// Global function used by FastUpdateLinkedData and FastUpdateFormManager
function setFastUpdateParams(label, uri) {
    let host = window.location.origin;
    let url =  new URL(host + $('#fast-update-search-preview').attr('href'));
    url.searchParams.append('old_uri', uri);
    url.searchParams.append('old_label', label);
    $('#fast-update-search-preview').attr('href', url.pathname + url.search);
}


class FastUpdateFieldManager extends ControlledVocabulary {

    constructor(element, paramKey) {
        let options = {
            /* callback to run after add is called */
            add:    null,
            /* callback to run after remove is called */
            remove: null,

            controlsHtml:      '<span class=\"input-group-btn field-controls\">',
            fieldWrapperClass: '.field-wrapper',
            warningClass:      '.has-warning',
            listClass:         '.listing',
            inputTypeClass:    '.controlled_vocabulary',//'.fast_update_form_field',

            addHtml:          '<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text"></span></button>',
            addText:           'Add another',

            removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"glyphicon glyphicon-remove\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
            removeText:         'Remove',

            labelControls:      true,
            /* the selector for the text input tag to add autocomplete to */

        }

        super(element, $.extend({}, options, $(element).data()))
        this.paramKey = paramKey
    }

    init() {
        this._addInitialClasses();
        this._addAriaLiveRegions();
        this._appendControls();
        this._attachEvents();
        this._addCallbacks();
        this._formatStringsAndLabels();
        this.addAutocompleteToEditor($('#new-label'));
    }

    _attachEvents() {
        this.element.on('click', this.removeSelector, (e) => this.removeFromList(e))
        this.element.on('click', this.addSelector, (e) => this.addToList(e))
    }

    _newFieldTemplate(target) {
        let index = this._maxIndex()
        let rowTemplate = this._template();
        let controls = this.controls.clone()//.append(this.remover)
        let row =  $(rowTemplate({ "paramKey": this.paramKey,
            "name": this.fieldName,
            "index": index,
            "class": "controlled_vocabulary" }))
            .append(controls)
        return row
    }

    _template() {
        return Handlebars.compile(this._source)
    }

    get _source() {
        return "<li class=\"field-wrapper input-group input-append\">" +
            "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[new_labels_and_uris][{{index}}][label]\" value=\"\" placeholder=\"Search for an entity\" id=\"{{paramKey}}_{{name}}_{{index}}\" data-attribute=\"{{name}}\" data-autocomplete-type=\"linked\" type=\"text\">" +
            "<input name=\"{{paramKey}}[new_labels_and_uris][{{index}}][uri]\" value=\"\" id=\"{{paramKey}}_{{name}}_{{index}}\" type=\"hidden\" data-id=\"remote\">"
    }

    /**
     * Make new element have autocomplete behavior
     * @param {jQuery} input - The <input type="text"> tag
     */
    addAutocompleteToEditor(input) {
        let autocomplete = new FastUpdateAutocomplete()
        autocomplete.setup(input, this.element.data('fieldName'), this.element.data('autocomplete-url'))
    }

    createAddHtml(options) {
        var $addHtml  = $('<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text"></span></button>')
        $addHtml.find('.controls-add-text').html(options.addText + options.label);
        return $addHtml;
    }

}

class FastUpdateAutocomplete extends autocompleteModule {

    byDataAttribute(element, url) {
        let type = element.data('autocomplete-type')

        if(type === 'linked') {
            new FastUpdateLinkedData(element, url)
        } else {
            new Default(element, url)
        }
    }

    byFieldName(element, fieldName, url) {
        switch (fieldName) {
            case 'collection':
                new FastUpdateResource(
                    element,
                    url)
                break
        }
    }

}

// Overwrite this to prevent input from changing to readonly
// when selected
class FastUpdateLinkedData extends LinkedData {

    selected(elem) {
        let result = this.element.select2("data")
        if (result.id.startsWith("fst")) {
            let uri = uriFromId(result['id']);
            // set the URI
            this.setIdentifier(uri);
            // Set the label
            this.element.val(result['label']);
            if (this.element.attr('id') == "old-label") {
                setFastUpdateParams(result['label'], uri);
            }
        } else {
            this.setIdentifier(result.id);
        }
        $('#fast-update-submit-button').removeClass('disabled');

        function uriFromId(fastId) {
            return 'http://id.worldcat.org/fast/' + fastId.replace('fst','').replace(/^0+/, '');
        }

    }
}

class FastUpdateResource extends Resource {

    initUI(element) {
        this.element = element
        element.select2( {
            minimumInputLength: 2,
            initSelection : (row, callback) => {
                var data = {id: row.val(), text: row.val()};
                callback(data);
            },
            ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
                url: this.url,
                dataType: 'json',
                data: (term, page) => {
                    return {
                        q: term, // search term
                        id: this.excludeWorkId // Exclude this work
                    };
                },
                results: this.processResults
            }
        }).select2('data', null).on("change", (e) => { this.selected(e) });
    }

    selected(e) {
        // Update search preview params
        let collection = e.added.text;
        let url =  new URL(window.location.origin + $('#fast-update-search-preview').attr('href'));
        // Reset the collection ID if one was previously selected
        if (url.searchParams.has('f[member_of_collections_ssim][]')) {
            url.searchParams.delete('f[member_of_collections_ssim][]');
        }
        url.searchParams.append('f[member_of_collections_ssim][]', collection);
        $('#fast-update-search-preview').attr('href', url.pathname + url.search);
    }

}

class ConfirmRemoveUriDialog extends ConfirmRemoveDialog {

    launch() {
        let dialog = $(this.template())
        dialog.find('[data-behavior="submit"]').click(() => {
            dialog.modal('hide');
            dialog.remove();
            this.fn();
        })
        dialog.modal('show')
    }

}

class FastUpdateFormManager {

    constructor(element) {
        this.element = $(element);
        // The selectors for elements to add autocomplete to
        this.autocompleteSelectors = ['#old-label','#fast_update_change_collection_id'];
        this.submitButton = $('#fast-update-submit-button');
        this.oldURIField = $('#fast_update_change_old_uri');
        this.init();
    }

    init() {
        // This causes JS errors if not removed
        $('#fast_update_change_collection_id').removeAttr('required');
        this._setupAutocomplete(this.autocompleteSelectors);
        this._attachToggleEvents();
        this._setURISearchParam();
        this._setupConfirmation();
    }

    _setupAutocomplete(selectors) {
        let elements = selectors.map(selector => $(selector));
        let autocomplete = new FastUpdateAutocomplete;
        elements.forEach(elem => addAutocomplete(elem));
        function addAutocomplete(element) {
            autocomplete.setup(element, element.data('autocomplete'), element.data('autocomplete-url'));
        }
    }

    _attachToggleEvents() {
        // Set initial state
        this._toggleDisabled($('#fast_update_change_collection_id_all'));
        let formManager = this;
        // Attach events
        $('.fast-update-form-group input[type=radio]').change( function(e) {
            formManager._toggleDisabled($(this));
            if ($(this).attr('id').includes('collection')) {
                formManager._updateCollectionParam($(this));
            }
        });
    }

    _toggleDisabled(elem) {
        let input = elem.closest('div[role=radiogroup]').siblings().first().find('input[data-autocomplete]');
        if (elem.attr('value') == 'delete' || elem.attr('value') == 'All') {
            input.prop('disabled','true');
        } else {
            input.removeAttr('disabled');
        }
    }

    _updateCollectionParam(elem) {
        // Reset the param if the collection id field has been enabled
        let collection = elem.closest('div').siblings().find('.select2-chosen').text();
        let url =  new URL(window.location.origin + $('#fast-update-search-preview').attr('href'));
        if (elem.attr('value') == 'all') {
            // Remove collection_id search param
            url.searchParams.delete('f[member_of_collections_ssim][]');
        } else {
            url.searchParams.append('f[member_of_collections_ssim][]', collection);
        }
        if (collection != "Search for a collection") {
            $('#fast-update-search-preview').attr('href', url.pathname + url.search);
        }
    }

    _setURISearchParam() {
        let oldLabelField = this.oldLabelField;
        this.oldURIField.on('change', function(e) {
            setFastUpdateParams( oldLabelField.val().trim(),$(this).val().trim());
        });
    }

    _setupConfirmation() {
        let form = this.element;
        let button = this.submitButton;
        button.click(function(e) {
            if ($('#fast_update_change_action_delete').is(':checked')) {
                e.preventDefault();
                let dialog = new ConfirmRemoveUriDialog(button.data('confirmText'),
                    button.data('confirmCancel'),
                    button.data('confirmRemove'),
                    // Unbind submit first so that default behavior is not prevented. From:
                    // https://stackoverflow.com/questions/1164132/how-to-reenable-event-preventdefault/1164177#1164177
                    () => { form.unbind('submit').submit() });
                dialog.launch();
                // To be less fancy, simply use
                // confirm(submitButton.data('confirmText'));
            }
            else { return; }
        });
    }
}