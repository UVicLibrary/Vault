$(document).on('turbolinks:load', function() {
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
    console.log(buttons)
    var currentIdx = buttons.index(e.target);

    // Move right
    if (e.keyCode === 39 || e.keyCode === 37) {
      buttons[currentIdx].setAttribute("tabindex", -1);
      buttons[currentIdx].setAttribute("aria-selected", false);
      if (e.keyCode === 39) {
        console.log('move right');
        currentIdx++;
        // If we're at the end, go to the start
        if (currentIdx >= buttons.length) {
          currentIdx = 0;
        }
        // Move left
      } else if (e.keyCode === 37) {
        console.log('move left');
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

  // Fix margin on work cards that aren't in any collections
  // var noCollectionLinks = $('.work-card .work-card-title').filter(function() {
  //     return !$(this).closest('.wrapper').find('.card-collection-link').length
  // });
  // noCollectionLinks.css('margin-bottom','0.7em')
});
