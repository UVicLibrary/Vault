import { FieldManager } from 'hydra-editor/field_manager'

export default class CustomControlledVocabulary extends FieldManager {

    constructor(element, controlledVocabulary) {
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
            addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"fa fa-plus\"></span><span class="controls-add-uri"></span></button><button type=\"button\" class=\"btn btn-link add add-text-field\"><span class=\"fa fa-plus\"></span><span class="controls-add-string"></span></button>',
            addText:           'Add a URI',
            addTextFieldText: 'Add text field',

            removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"fa fa-x\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
            removeText:         'Remove',

            labelControls:      true,
            addTextSelector: '.controls-add-string',
        }

        // Use inheritance and dependency injection to mix in methods
        // from FieldManager (hydra-editor) and ControleldVocabulary (hyrax)
        // classes respectively.
        // https://rasaturyan.medium.com/multiple-inheritance-in-javascript-es6-4999e4b6584c

        // hydra-editor/field_manager.es6
        super(element, $.extend({}, options, $(element).data()))

        // hyrax/editor/controlled_vocabulary.es6
        this.controlledVocabulary = controlledVocabulary
        this.paramKey = this.controlledVocabulary.paramKey
        // these 2 properties are needed to trigger autocomplete on URI fields
        // see createNewURIField()
        this.controlledVocabulary.fieldName = this.element.data('fieldName')
        this.controlledVocabulary.searchUrl = this.element.data('autocompleteUrl')
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

    // Overrides FieldManager, because field manager uses the wrong selector
   addToList( event ) {
       event.stopPropagation(); // Prevents duplicating extra text field
       event.preventDefault();
       let $listing = $(event.target).closest(this.inputTypeClass).find(this.listClass)
       // let $activeField = $listing.children('li').last()

       if (event.target.className == 'controls-add-uri') {
           var $newField = this.createNewURIField();
       } else { // add text field
           var $newField = this.createNewTextField();
       }
       $listing.append($newField);
        // If a field is initialized with no inputs, we have to append add/remove controls
       this._appendControls()
       this._manageFocus()
    }

    // Based on ControlledVocabulary's createNewField
    // Adds data-autocomplete-type='linked' to trigger autocomplete
    createNewURIField() {
        let $newField = this._baseTemplate()
        $('input.multi-text-field', $newField).data('autocomplete-type','linked')
        this.controlledVocabulary._addBehaviorsToInput($newField)
        return $newField
    }

    // Based on ControlledVocabulary's createNewField
    // Removes the 2nd id input, which is not necessary for string
    // values. (This also helps distinguish it from URIs later
    // in the controller.)
    createNewTextField() {
        let $newField = this._baseTemplate()
        let idToDelete = `#${this.paramKey}_${this.controlledVocabulary.fieldName}_attributes_${this._maxIndex()}_id`
        $(idToDelete, $newField).remove()
        return $newField
    }

    // Based on ControlledVocabulary's _newFieldTemplate
    // Uses the MixedControlledVocabulary's maxIndex instead of
    // the ControlledVocabulary's (the latter will always be 0)
    _baseTemplate() {
        let index = this._maxIndex()
        let rowTemplate = this.controlledVocabulary._template()
        let controls = this.controls.clone()
        return $(rowTemplate({ "paramKey": this.paramKey,
                               "name": this.controlledVocabulary.fieldName,
                               "index": index,
                               "class": "controlled_vocabulary" }))
                .append(controls)
    }

    // Creates the html element for "Add another" button and "Add text field" button
    createAddHtml(options) {
        var $addHtml  = $(options.addHtml);
        $addHtml.find('.controls-add-uri').html(options.addText);
        $addHtml.find('.controls-add-string').html(options.addTextFieldText);
        return $addHtml
    }

    /* This gives the index for the editor */
    _maxIndex() {
        return $(this.fieldWrapperClass, this.element).length
    }

    // Override FieldManager to always return false
    // because we always want to permit adding another row
    inputIsEmpty(_) {
        return false
    }

    // Use the ControlledVocabulary function for this instead
    // of the default FieldManager
   removeFromList( event ) {
        this.controlledVocabulary.removeFromList(event)
   }

}