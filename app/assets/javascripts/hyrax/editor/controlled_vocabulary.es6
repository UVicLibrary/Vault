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
            addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text"></span></button><button type=\"button\" class=\"btn btn-link add-text-field\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text-field-text" "></span></button>',
            addText:           'Add a URI',
            addTextFieldText: 'Add text field',

            removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"glyphicon glyphicon-remove\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
            removeText:         'Remove',

            labelControls:      true,
            addTextSelector: '.controls-add-text-field-text',
        }
        super(element, $.extend({}, options, $(element).data()))
        this.paramKey = paramKey
        // defines what element to attach the addTextFieldToList function to
        // this.addTextSelector = '.controls-add-text-field-text'
        this.fieldName = this.element.data('fieldName')
        this.searchUrl = this.element.data('autocompleteUrl')


    }

    // Copied from app/assets/javascripts/hydra-editor/field_manager.es6
    _attachEvents() {
        this.element.on('click', this.removeSelector, (e) => this.removeTextFieldFromList(e))
        this.element.on('click', this.addSelector, (e) => this.addToList(e))
        this.element.on('click', this.options.addTextSelector, (e) => this.addTextFieldToList(e))
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
        this._addAriaLiveRegions()
        this._appendControls();
        this._attachEvents();
        this._addCallbacks();
        this._convertStringInputs();
    }

    // convert string/text values into the proper template. Add labels to URI fields.
    // Labels and strings are read from a data attribute set in the edit field partial.
    _convertStringInputs() {
        let fields = $(this.element.find('.listing').children('li'))
        // Retrieve the values from data attributes in view partials (views/records/vault/...)
        let labelValues = fields.first().children('input').first().data('labelValues')
        fields.each(function(index, field) {
            if (typeof labelValues !== 'undefined' && labelValues.length > 0) {
                // Remove autocomplete for string values
                if (labelValues[index].hasOwnProperty('string')) {
                    $(field).children('input').not(':first').remove()
                    var inputField = $(field).children('input')
                    inputField.attr('id',inputField.attr('class').split(' ')[4])
                    var fieldName = inputField.attr('id').replace('generic_work_','')
                    inputField.attr('name','generic_work[' + fieldName + '][]')
                    inputField.select2('destroy')
                    inputField.removeAttr('readonly value data-autocomplete-url data-attribute placeholder')
                    inputField.val(labelValues[index]['string'])
                } else { // Display the label
                    console.log("uri = " + labelValues[index]['uri'])
                    $(field).children('input').eq(1).attr('value', labelValues[index]['uri'])
                    console.log($(field).children('input').eq(1).attr('value'))
                    $(field).find('span.select2-chosen').text(labelValues[index]['label'])
                    $(field).children('input').first().attr('readonly', true)
                }
            }
        });
    }

    // Overrides FieldManager, because field manager uses the wrong selector
    addToList( event ) {
        event.stopPropagation(); // Prevents duplicating extra text field
        event.preventDefault();
            let $listing = $(event.target).closest(this.inputTypeClass).find(this.listClass)
            $(event.target).closest(this.inputTypeClass).find(this.listClass)
            let $activeField = $listing.children('li').last()
            $listing.append(this._newField($activeField));
             // If a field is initialized with no inputs, we have to append add/remove controls
            this._appendControls()
            this._manageFocus()
    }

    addTextFieldToList( event ) {
        event.stopImmediatePropagation();
        event.stopPropagation()
        event.preventDefault();

        let $listing = $(event.target).closest(this.inputTypeClass).find(this.listClass)
        let $activeField = $listing.children('li').last()
        if (this.inputIsEmpty($activeField)) {
            this.displayEmptyWarning();
        } else {
            this.clearEmptyWarning();
            $listing.append(this._newTextField($activeField));
        }

        // If a field is initialized with no inputs, we have to append add/remove controls
        this._appendControls()
        this._manageFocus()
    }

    // Overrides FieldManager in order to avoid doing a clone of the existing field
    createNewField() {
        let $newField = this._newFieldTemplate()
        this._addBehaviorsToInput($newField)
        this.element.trigger("managed_field:add", $newField);
        return $newField
    }

    createNewTextField() {
        let $newField = this._newTextFieldTemplate()
        this.element.on('click', this.removeSelector, (e) => this.removeTextFieldFromList(e))
        this.element.trigger("managed_field:add", $newField);
        return $newField
    }

    _newTextField () {
        var $newField = this.createNewTextField();
        return $newField;
    }


    // Creates the html element for "Add another" button and "Add text field" button
    createAddHtml(options) {
        var $addHtml  = $(options.addHtml);
        $addHtml.find('.controls-add-text').html(options.addText + options.label);
        $addHtml.find('.controls-add-text-field-text').html(options.addTextFieldText + options.label);
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

    _newFieldTemplate() {
        let index = this._maxIndex()
        let rowTemplate = this._template()
        let controls = this.controls.clone()//.append(this.remover)
        let row =  $(rowTemplate({ "paramKey": this.paramKey,
            "name": this.fieldName,
            "index": index,
            "class": "controlled_vocabulary" }))
            .append(controls)
        return row
    }

    _newTextFieldTemplate() {
        let index = this._maxIndex()
        let rowTemplate = this._textFieldTemplate()
        let controls = this.controls.clone()//.append(this.remover)
        let row =  $(rowTemplate({ "paramKey": this.paramKey,
            "name": this.fieldName,
            "index": index,
            "class": "multi_value" }))
            .append(controls)
        return row
    }


    get _textSource() {
        return "<li class=\"field-wrapper input-group input-append\">" +
            "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}][]\" value=\"\" id=\"{{paramKey}}_{{name}}\" aria-labelledby=\"{{paramKey}}_{{name}}_label\" type=\"text\">"
    }

    get _source() {
        return "<li class=\"field-wrapper input-group input-append\">" +
            "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
            "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
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
        this.addAutocompleteToEditor($newInput)
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

    removeTextFieldFromList( event ) {
        // event.preventDefault();
        var $field = $(event.target).parents(this.fieldWrapperClass).remove();
        this.element.trigger("managed_field:remove", $field);
        this._manageFocus();
    }
}