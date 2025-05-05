$(document).on('turbolinks:load', function() {

    var buttons = $('button[data-toggle="tab"]');
    buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected

    // When a user clicks the all collection tab and then another tab, we need to
    // change the 'All collections' link to match the (list or card) view that
    // was previously shown
    $('.all-collections-button, .list-collections-button').click( function() {
        $('#all-collections-tab').attr('href', $(this).attr('href'));
        // Collapse the clicked button
        $(this).addClass('collapse');
        // Show the other button
        if ($(this).attr('href') == '#all-collections') {
            $('.list-collections-button').removeClass('collapse');
        } else {
            $('.all-collections-button').removeClass('collapse');
        }
    });

    $('#featured-nav button[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        // adjust height of card titles based on the length of the title
        transformCards();

        // show the correct button if on the 'All Collections' tab
        if ($(this).data('header') == 'All Collections') {
            // If we are on the 'card' view
            if ($(this).attr('href') == '#all-collections') {
                // show the 'List All' button
                $('.list-collections-button').removeClass('collapse');
            } else {
                // show the 'Card View' button
                $('.all-collections-button').removeClass('collapse');
            }
        } else {
            // collapse/reset both buttons
            $('.list-collections-button').addClass('collapse');
            $('.all-collections-button').addClass('collapse');
        }
    });

    // Update the header when a tab is shown
    $('button[data-toggle="tab"]').on('shown.bs.tab', function () {
        if (!$(this).hasClass('list-collections-button') && !$(this).hasClass('all-collections-button')) {
            buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected
            // Update the header
            var header = $($(this).closest('div:not([role=tablist])').find('h2'));
            var container = header.parent();
            var newHeader = header.clone().html($(this).data('header'));
            header.remove();
            container.prepend(newHeader);
        }
    });

    // Allow users to navigate tabs using left and right arrow keys. See
    // guidelines for "tabs with automatic activation":
    // https://www.w3.org/WAI/ARIA/apg/patterns/tabs/examples/tabs-automatic/
    $('button[data-toggle="tab"]').keydown(function(e) {
        if (!$(this).hasClass('list-collections-button') && !$(this).hasClass('all-collections-button')) {
            // Get the index of the current button
            var buttons = $(e.target.closest('div[role=tablist]')).find('button');
            var currentIdx = buttons.index(e.target);

            // When pressing right (39) or left (37) arrow keys
            if (e.keyCode === 39 || e.keyCode === 37) {
                buttons[currentIdx].setAttribute("tabindex", -1);
                buttons[currentIdx].setAttribute("aria-selected", false);
                if (e.keyCode === 39) {
                    currentIdx++;
                    // If we're at the end, go to the start
                    if (currentIdx >= buttons.length) {
                        currentIdx = 0;
                    }
                    // Move left
                } else if (e.keyCode === 37) {
                    currentIdx--;
                    // If we're at the start, move to the end
                    if (currentIdx < 0) {
                        currentIdx = buttons.length - 1;
                    }
                }
                $(buttons[currentIdx]).tab('show')
                buttons.removeAttr('aria-expanded')
                $(buttons[currentIdx]).attr({"tabindex": 0, "aria-selected": true})
                buttons[currentIdx].focus();
            }

            // If focused on the homepage facet buttons ("Browse by") and press Shift + tab, jump to the help link
            if (e.shiftKey && e.keyCode == 9 && $(this).closest('ul').attr('id') == 'browse-by-nav') {
                e.preventDefault()
                $('.help-link').focus()
            }
        }
    });

    // Prevent Feature/Unfeature collection button from firing twice
    $('#feature-coll-link, #unfeature-coll-link').on('click', function() {
        $(this).prop('disabled', true);
    });

    window.addEventListener('workCardsLoaded', function(e) { transformCards() });

    function transformCards() {
        // Adjust position of work-card titles based on height
        $('.homepage-card.work-card .data').each(function(index) {
            card = $($('.homepage-card.work-card .data')[index]);
            hideDescr(card);
        });
        // Move the description up so it is visible on hover
        $('.homepage-card.work-card .wrapper').on({
            mouseenter: function() {
                showDescr($(this).find('.data'));
            }, mouseleave: function() {
                hideDescr($(this).find('.data'));
            }
        })

        function hideDescr(card) {
            cardHeight = card.closest('.wrapper').outerHeight();
            titleHeight= $(card.find('.homepage-card-title')).outerHeight();

            link = card.closest('.wrapper').find('.card-collection-link');
            linkHeight = (link.length != 0 ? link.outerHeight() : 0);

            card.css('transform','translateY(' + (cardHeight - (titleHeight + linkHeight + 33)) + 'px)');
        }

        function showDescr(card) {
            cardHeight = card.closest('.wrapper').outerHeight();
            titleHeight= $(card.find('.homepage-card-title')).outerHeight();

            link = card.closest('.wrapper').find('.card-collection-link');
            linkHeight = (link.length != 0 ? link.outerHeight() : 0);

            card.css('transition', 'transform 0.3s').css('transform', 'translateY(' + (cardHeight - (titleHeight + linkHeight + 112)) + 'px)');
        }
    }



});


