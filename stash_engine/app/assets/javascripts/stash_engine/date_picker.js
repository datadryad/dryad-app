
function initDatePicker() {
  // If the browser does not support the HTML5 date field yet,
  // attach the JQuery UI date picker to the date fields
  if ( $('[type="date"]').prop('type') != 'date' ) {
    $('[type="date"]').datepicker({
      dateFormat: 'yy-mm-dd',
      constrainInput: true,
      minDate: 0,
      navigationAsDateFormat: true
    });
  }
};
