//= require "handlebars-v4.0.5"

import { FieldManager } from 'hydra-editor/field_manager'
import Handlebars from 'handlebars'
import Autocomplete from 'hyrax/autocomplete'

export default class ControlledVocabulary extends FieldManager {

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
            inputTypeClass:    '.controlled_vocabulary',

            // add html for "add text field" option; the add-text-field class is called by the addTextFieldText function
            addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-uri"></span></button><button type=\"button\" class=\"btn btn-link add-text-field\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-string"></span></button>',
            addText:           'Add a URI',
            addTextFieldText: 'Add text field',

            removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"glyphicon glyphicon-remove\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
            removeText:         'Remove',

            labelControls:      true,
            addTextSelector: '.controls-add-string',
        }
        super(element, $.extend({}, options, $(element).data()))
        this.paramKey = paramKey
        // defines what element to attach the addTextFieldToList function to
        this.fieldName = this.element.data('fieldName')
        this.searchUrl = this.element.data('autocompleteUrl')


    }

    // Copied from app/assets/javascripts/hydra-editor/field_manager.es6 and modified
    _attachEvents() {
        this.element.on('click', this.removeSelector, (e) => this.removeFromList(e))
        this.element.on('click', this.addSelector, (e) => this.addToList(e))
        this.element.on('click', this.options.addTextSelector, (e) => this.addToList(e))
    }

    // Add the "Add another" and "Remove" controls to the DOM
    _appendControls() {
        // We want to make these DOM additions idempotently, so exit if it's
        // already set up.
        if (!this._hasRemoveControl()) {
            this._createRemoveWrapper()
            this._createRemoveControl()
        }

        if (!this._hasAddControl()) {
            this._createAddControl()
        }

        // Bug where two remove controls are added
        if (this.element.find(this.removeSelector).length > 1 && this.element.find('li').length === 1) {
            this.element.find(this.removeSelector)[0].remove()
        }
    }

    init() {
        this._addInitialClasses();
        this._addAriaLiveRegions();
        this._appendControls();
        this._attachEvents();
        this._addCallbacks();
        this._formatStringsAndLabels();
    }

    // convert string/text values into the proper template. Add labels to URI fields.
    // Labels and strings are read from a data attribute set in the edit field partial.
    _formatStringsAndLabels() {
        let fields = $(this.element.find('.listing').children('li'));
        var controlledVocab = $(this)[0];
        // Retrieve the values from data attributes in view partials (views/records/vault/...)
        let labelValues = this.element.data('label-values');
        fields.each(function(index, field) {
            if (typeof labelValues !== 'undefined' && labelValues.length > 0) {
                let value = labelValues[index];
                if (labelValues[index].hasOwnProperty('string')) {
                    $(field).first().children('input').first().val(value['string']);
                    $(field).first().children('input').first().attr('readonly', false)
                } else { // Display the label for URIs
                    $(field).children('input').eq(1).attr('value', value['uri'])
                    $(field).find('span.select2-chosen').text(value['label'])
                    $(field).children('input').first().attr('readonly', false)
                }
            }
        });
    }

    // Overrides FieldManager, because field manager uses the wrong selector
    addToList( event ) {
        event.stopPropagation(); // Prevents duplicating extra text field
        event.preventDefault();
        let $listing = $(event.target).closest(this.inputTypeClass).find(this.listClass)
        let $newField = this.createNewField(event.target);
        $listing.append($newField);
        // If a field is initialized with no inputs, we have to append add/remove controls
        this._appendControls()
        this._manageFocus()
    }

    // Overrides FieldManager in order to avoid doing a clone of the existing field
    createNewField(target) {
        let $newField = this._newFieldTemplate(target);
        this._addBehaviorsToInput($newField);
        this.element.trigger("managed_field:add", $newField);
        return $newField;
    }

    // Creates the html element for "Add another" button and "Add text field" button
    createAddHtml(options) {
        var $addHtml  = $(options.addHtml);
        $addHtml.find('.controls-add-uri').html(options.addText + options.label);
        $addHtml.find('.controls-add-string').html(options.addTextFieldText + options.label);
        return $addHtml;
    }

    /* This gives the index for the editor */
    _maxIndex() {
        return $(this.fieldWrapperClass, this.element).length
    }

    // Overridden because we always want to permit adding another row
    inputIsEmpty(activeField) {
        return false
    }

    _newFieldTemplate(target) {
        let index = this._maxIndex()
        if (target.className == 'controls-add-uri') {
            var rowTemplate = this._template();
        } else {
            var rowTemplate = this._textFieldTemplate();
        }
        let controls = this.controls.clone()//.append(this.remover)
        let row =  $(rowTemplate({ "paramKey": this.paramKey,
            "name": this.fieldName,
            "index": index,
            "class": "controlled_vocabulary" }))
            .append(controls)
        return row
    }

    get _source() {
        return "<li class=\"field-wrapper input-group input-append\">" +
            "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" data-autocomplete-type=\"linked\" type=\"text\">" +
            "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
            "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][_destroy]\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"></li>"
    }

    get _textSource() {
        return "<li class=\"field-wrapper input-group input-append\">" +
            "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{paramKey}}_{{name}}\" data-attribute=\"{{name}}\" type=\"text\">" +
            "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][_destroy]\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"></li>"
    }

    _template() {
        return Handlebars.compile(this._source)
    }

    _textFieldTemplate() {
        return Handlebars.compile(this._textSource)
    }

    /**
     * @param {jQuery} $newField - The <li> tag
     */
    _addBehaviorsToInput($newField) {
        let $newInput = $('input.multi-text-field', $newField)
        $newInput.focus()
        if ($newInput.data('autocomplete-type')) {
            this.addAutocompleteToEditor($newInput)
        }
        this.element.trigger("managed_field:add", $newInput)
    }

    /**
     * Make new element have autocomplete behavior
     * @param {jQuery} input - The <input type="text"> tag
     */
    addAutocompleteToEditor(input) {
        var autocomplete = new Autocomplete()
        autocomplete.setup(input, this.fieldName, this.searchUrl)
    }

    // Overrides FieldManager
    // Instead of removing the line, we override this method to add a
    // '_destroy' hidden parameter
    removeFromList( event ) {
        event.preventDefault()
        let field = $(event.target).parents(this.fieldWrapperClass)
        field.find('[data-destroy]').val('true')
        field.hide()
        this.element.trigger("managed_field:remove", field)
    }
}