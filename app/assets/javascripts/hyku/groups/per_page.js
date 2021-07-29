$(document).on('turbolinks:load', function() {
  $('.js-per-page__submit').hide();
  $('.js-per-page__select').on('change', function() {
    $(this).parents('.js-per-page').submit();
  });
  
  // Changes the header ("Featured ____") to match the tab that is currently active
  $("h1#featured-header").html($("ul#featured-nav li.active").text());
  $('#featured-nav a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      var target = e.target.attributes.href.value;
      $("h1#featured-header").html(e.target.innerText);
      // Manage focus for accessibility: focus on the first card in the tab pane so
      // screen readers know the page changed
      $(target + ' .plain-link:first').focus();
  })

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

    // Fix margin on work cards that aren't in any collections
    // var noCollectionLinks = $('.work-card .work-card-title').filter(function() {
    //     return !$(this).closest('.wrapper').find('.card-collection-link').length
    // });
    // noCollectionLinks.css('margin-bottom','0.7em')
});
