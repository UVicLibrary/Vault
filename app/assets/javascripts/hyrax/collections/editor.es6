import ThumbnailSelect from 'hyrax/thumbnail_select'
import Participants from 'hyrax/admin/admin_set/participants'
import tabifyForm from 'hyrax/tabbed_form'
import ControlledVocabulary from 'hyrax/editor/controlled_vocabulary'
import Autocomplete from 'hyrax/autocomplete'
import AuthoritySelect from 'hyrax/authority_select'

// Controls the behavior of the Collections edit form
// Add search for thumbnail to the edit descriptions
export default class {
    constructor(elem) {
        let url =  window.location.pathname.replace('edit', 'files')
        let field = elem.find('#collection_thumbnail_id')
        this.thumbnailSelect = new ThumbnailSelect(url, field)
        this.element = elem
        tabifyForm(elem.find('form.editor'))

        let participants = new Participants(elem.find('#participants'))
        participants.setup()
        if (window.location.href.includes("collection")) {
            this.init()
        }
    }

    init() {
        this.autocomplete()
        this.controlledVocabularies()
        this.authoritySelect()
    }

    // Used when you have a linked data field that can have terms from multiple
    // authorities.
    authoritySelect() {
        $("[data-authority-select]").each(function() {
            let authoritySelect = $(this).data().authoritySelect
            let options =  {selectBox: 'select.' + authoritySelect,
                inputField: 'input.' + authoritySelect}
            new AuthoritySelect(options);
        })
    }

    // Autocomplete fields for the work edit form (based_near, subject, language, child works)
    autocomplete() {
        var autocomplete = new Autocomplete()

        $('[data-autocomplete]').each((function() {
            var elem = $(this)
            autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
        }))

        $('.multi_value.form-group').manage_fields({
            add: function(e, element) {
                var elem = $(element)
                // Don't mark an added element as readonly even if previous element was
                // Enable before initializing, as otherwise LinkedData fields remain disabled
                elem.attr('readonly', false)
                autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
            }
        })
    }

    //initialize any controlled vocabulary widgets
    controlledVocabularies() {
        this.element.find('.controlled_vocabulary.form-group').each((_idx, controlled_field) =>
            new ControlledVocabulary(controlled_field, this.paramKey)
        )
    }

}
