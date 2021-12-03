$(document).on('turbolinks:load', function() {
    $('#load-more-button a').click(function () { showLoadingText() });

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
        $('html, body').animate({scrollTop:300}, '300');
    });
});

function showLoadingText() {
    var loadingText = [
        "<span class='loading-text'>Loading</span>",
        "<img src='/browse_collections/Spinner-1s-200px.gif' width='60px' />"
    ]
    $('#load-more-button').css('visibility','hidden');
    $('.load-more-button-wrapper').prepend(loadingText.join(""));
}


