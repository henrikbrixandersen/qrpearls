/**
 * This is where it all begins.
 */
jQuery(function($) {
    // Hide address bar on iOS devices.
    setTimeout('window.scrollTo(0, 0);', 0);

    // Language selection handler.
    $('.lang-select').click(function() {
	document.cookie='lang=' + $(this).data('lang') + '; Path=/';
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
	if (validateFormInput()) {
	  $('#modal-preview').modal({remote: '/qrcode.pl?preview=1&' + $('#form').serialize()});
	}
      });
    $('#modal-preview').on('hidden', function() {
	$(this).removeData('modal');
	$('.modal-body', this).empty();
      });

    // Form submit handler.
    $('#form').submit(function() {
	return validateFormInput();
      });

    // Auto-focus input field on non-touch devices.
    focusTextInput();
  });

/**
 * Function to conditionally focus text input field.
 */
function focusTextInput() {
    var touchSupported = isMouseEventSupported('touchmove');
    if (!touchSupported) {
      $('#form-text').focus();
    }
}

/**
 * Function to validate form input.
 */
function validateFormInput() {
  if ($('#form-text').val().length == 0) {
    $('#alert-no-text').fadeIn();
    focusTextInput();
    return false;
  } else {
    $('#alert-no-text').fadeOut();
    return true;
  }
}

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
