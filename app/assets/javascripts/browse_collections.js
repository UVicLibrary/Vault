// Javascript for homepage cards and back to top button
$(document).on('turbolinks:load', function() {
    $('.load-more-button a').click(function (e) {
        showLoadingText(e);
    });

    var backToTop = $('#back-to-top');
    $(window).scroll(function() {
        if ($(window).scrollTop() > 900) {
            backToTop.addClass('show');
        } else {
            backToTop.removeClass('show');
        }
    });
    backToTop.on('click', function(e) {
        e.preventDefault();
        $('html, body').animate({scrollTop:0}, '300');
    });
});

function showLoadingText(e) {
    var loadingText = [
       "<div class='loading-wrapper'>",
         "<span class='loading-text'>Loading</span>",
         "<img src='/vault_homepage/Spinner-1s-200px.gif' width='60px' />",
       "</div>"
    ]
    $(e.target).parent().addClass('hide-load-more');
    $(e.target).closest('.load-more-button-wrapper').prepend(loadingText.join(""));
}

window.addEventListener('workCardsLoaded', function(e) { transformCards() });

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
}

