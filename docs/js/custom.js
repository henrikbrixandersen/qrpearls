/**
 * Attach language selection handler.
 */
$(".lang-select").click(function() {
    document.cookie="lang=" + $(this).data('lang');
    location.reload();
    return false;
});
