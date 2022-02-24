$(document).on('turbolinks:load', function() {
    $('.load-more-button a').click(function (e) { showLoadingText(e) });

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
        "<span class='loading-text'>Loading</span>",
        "<img src='/browse_collections/Spinner-1s-200px.gif' width='60px' />"
    ]
    $(e.target).parent().css('visibility','hidden');
    $(e.target).closest('.load-more-button-wrapper').prepend(loadingText.join(""));
}


