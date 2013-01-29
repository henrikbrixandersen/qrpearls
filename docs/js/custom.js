/**
 * This is where it all begins.
 */
$(document).ready(function() {
    // Browser touch event support
    var touchSupported = isMouseEventSupported('touchmove');

    // Hide address bar on iOS devices.
    setTimeout('window.scrollTo(0, 0);', 0);

    // Language selection handler.
    $('.lang-select').click(function() {
	document.cookie='lang=' + $(this).data('lang');
	location.reload();
	return false;
      });

    // Alert close button handler.
    $("#alert-no-text-close").click(function() {
	$('#alert-no-text').fadeOut();
      });

    // Text typeahead choices.
    $('#form-text').typeahead({source: ['http://',
					'https://',
					'mailto:',
					'tel:',
					'sms:',
					'mms:']});

    // Form preview handler.
    $('#form-preview').click(function() {
	$('#modal-preview').modal();
      });

    // Form submit handler.
    $('#form').submit(function() {
	if ($('#form-text').val().length == 0) {
	  $('#alert-no-text').fadeIn();
	  return false;
	}

	return true;
      });

    // Autofocus input field on non-touch devices.
    if (!touchSupported) {
      $('#form-text').focus();
    }
  });


/**
 * Function to test whether a given mouse event is supported.
 */
function isMouseEventSupported(eventName) {
  var eventName = 'on' + eventName;
  var el = document.createElement('div');
  var isSupported = (eventName in el);

  if (!isSupported) {
    el.setAttribute(eventName, 'return;');
    isSupported = typeof el[eventName] == 'function';
  }

  el = null;

  return isSupported;
}
