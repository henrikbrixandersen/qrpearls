/**
 * Language selection handler.
 */
$('.lang-select').click(function() {
    document.cookie='lang=' + $(this).data('lang');
    location.reload();
    return false;
});

/**
 * Alert close button handler.
 */
$("#alert-no-text-close").click(function() {
    $('#alert-no-text').fadeOut();
});

/**
 * Text typeahead choices.
 */
$('#inputText').typeahead({source: ['http://', 'https://', 'mailto:', 'tel:', 'sms:', 'mms:']});

/**
 * Form submit handler.
 */
$('#form').submit(function() {
    if ($('#inputText').val().length == 0) {
      $('#alert-no-text').fadeIn();
      return false;
    }

    return true;
});
