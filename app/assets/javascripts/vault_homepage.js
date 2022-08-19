$(document).on('turbolinks:load', function() {

    function hideDescr(card) {
        titleHeight= $(card.find('.card-title')).outerHeight();
        linkHeight = $(card.parent().siblings()[0]).innerHeight() || 7;
        cardHeight = parseInt($('.card.col-lg-3 .wrapper').css('min-height'));
        card.css('transform','translateY(' + (cardHeight - linkHeight - titleHeight - 28) + 'px)');
    }

    function showDescr(card) {
        cardHeight = parseInt($('.card.col-lg-3 .wrapper').css('min-height'));
        linkHeight = $(card.parent().siblings()[0]).innerHeight() || 7;
        titleHeight= $(card.find('.card-title')).outerHeight();
        card.css('transition', 'transform 0.3s').css('transform', 'translateY(' + (cardHeight - linkHeight -titleHeight - 98) + 'px)');
    }

    function transformCards() {
        // Adjust position of work-card titles based on height
        $('.card.work-card .data').each(function(index) {
            card = $($('.card.work-card .data')[index]);
            hideDescr(card);
        });
        // Move the description up so it is visible on hover
        $('.card.work-card .wrapper').on({
            mouseenter: function() {
                showDescr($(this).find('.data'));
            }, mouseleave: function() {
                hideDescr($(this).find('.data'));
            }
        })
    }

    $('.all-collections-button, .list-collections-button').click( function() {
        // Change the link on the featured nav button to match the button that
        // was just clicked. This makes sure we display the correct tab (list or
        // card view) the next time the "All Collections" button is clicked.
        $('#all-collections-tab').attr('href', $(this).attr('href'));
        // Collapse the clicked button
        $(this).css('display','');
        $(this).addClass('collapse');
        // Show the other button
        if ($(this).attr('href') == '#all-collections') {
            $('.list-collections-button').removeClass('collapse');
        } else {
            $('.all-collections-button').removeClass('collapse');
        }
    });

    // Set initial states
    // Changes the header ("Featured ____") to match the tab that is currently active
    // $("h1#featured-header").html($("#featured-nav li.active").text());
    var buttons = $('button[data-toggle="tab"]');
    buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected

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
            $('.list-collections-button').css('display','');
            $('.all-collections-button').css('display','');
            $('.list-collections-button').addClass('collapse');
            $('.all-collections-button').addClass('collapse');
        }
    });

    $('button[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        if (!$(this).hasClass('list-collections-button') && !$(this).hasClass('all-collections-button')) {
            buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected
            // Update the header
            var header = $($(this).closest('div').find('h1'));
            var container = header.parent();
            var newHeader = header.clone().html($(this).data('header'));
            header.remove();
            container.prepend(newHeader);
        }
    });

    // Make the tabs keyboard accessible with left and right arrows
    // Accessibility design pattern: https://www.w3.org/TR/wai-aria-practices-1.2/#tabpanel
    $('button[data-toggle="tab"]').keydown(function(e) {
        if (!$(this).hasClass('list-collections-button') && !$(this).hasClass('all-collections-button')) {
            e.preventDefault();
            // Get the index of the current button
            var buttons = $(e.target.closest('ul')).find('button');
            var currentIdx = buttons.index(e.target);

            // Move right
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

            // Shift-tab, go to previous element, go to next element outside buttons
            if (e.shiftKey && e.keyCode == 9 && $(this).closest('ul').attr('id') == 'browse-by-nav') {
                $('.help-link').focus()
            } else if (e.shiftKey && e.keyCode == 9) { //$(this).closest('ul').attr('id') == 'featured-nav')
                // detect which tab in "browse by" is currently active
                // focus on the last element in that tab
                $('.browse-by-container').find('.tab-pane.active').find('.last-child').focus()
            }
            // tab key pressed, go to next element outside buttons
            if (!e.shiftKey && e.keyCode == 9) {
                var tabPanelId = $(e.target.closest('ul')).find('li.active button')[0].attributes.href.value;
                $(tabPanelId).first().find('.homepage-tab-link').first().focus()
            }
        }
    });

    // Pressing tab when on the last homepage facet link still takes you to
    // the 'List All' or 'Card View' buttons even when they are tab-index="-1"
    // This fixes that.
    $('.homepage-facet-link.last-child').keydown(function(e) {
        e.preventDefault();
        if (!e.shiftKey && e.keyCode == 9) {
            $('#featured-nav li.active button').focus();
        }
    });

    // Prevent Feature/Unfeature collection button from firing twice
    $('#feature-coll-link, #unfeature-coll-link').on('click', function() {
        $(this).prop('disabled', true);
    });

});