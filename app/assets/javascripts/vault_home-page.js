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

    $('button[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        transformCards();
    });


    // Set initial states
    // Changes the header ("Featured ____") to match the tab that is currently active
    $("h1#featured-header").html($("#featured-nav li.active").text());
    var buttons = $('#featured-nav button[data-toggle="tab"]');
    buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected

    $('#featured-nav button[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        buttons.removeAttr('aria-expanded') // We will manage aria separately using aria-selected
        // Update the header
        $("h1#featured-header").html(e.target.innerText);
    });

    // Make the tabs keyboard accessible with left and right arrows
    // Accessibility design pattern: https://www.w3.org/TR/wai-aria-practices-1.1/#tabpanel
    $('#featured-nav button[data-toggle="tab"]').keydown(function(e) {
        e.preventDefault()
        // Get the index of the current button
        var buttons = $('#featured-nav button[data-toggle="tab"]');
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
        if(e.shiftKey && e.keyCode == 9) {
            console.log('shift tab')
            $('#search-submit-header').focus()
        }
        // tab key pressed, go to next element outside buttons
        if (!e.shiftKey && e.keyCode == 9) {
            console.log('tab only')
            var tabPanelId = $('#featured-nav li.active button')[0].attributes.href.value;
            $(tabPanelId).first().find('.plain-link').first().focus()
        }

    });


    // Refresh the collections or works list if user clicks pagination link
    $("#homepage-works-and-collections").on('click', '.pagination a', function() {
        var c = "#collections-partial";
        var w = "#works-partial";
        if ($(this).closest(c) || $(this).closest(w)) {
            $(this).closest(':has(tbody)').find('tbody').css('opacity','0.6');
            $(this).closest('.pagination').html('Loading results...');
            $.get(this.href, null, null, "script"); // views/hyrax/homepage/index.js.erb
            return false;
        }
        return false;
    });

    // Prevent Feature/Unfeature collection button from firing twice
    $('#feature-coll-link, #unfeature-coll-link').on('click', function() {
        $(this).prop('disabled', true);
    });

});


