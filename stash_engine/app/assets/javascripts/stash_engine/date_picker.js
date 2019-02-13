$(document).ready(function(){

  function initDatePicker() {

console.log("FUNCTION CALLED");

    // If the browser does not support the HTML5 date field yet,
    // attach the JQuery UI date picker to the date fields
    if ( $('[type="date"]').prop('type') != 'date' ) {
      $('[type="date"]').datepicker();
    }


    // $('input[type="date"]').datepicker();

    $('input[type="date"]').on('focus', function(){
  console.log('We are here!');
    });

    $('#publication_date').click(function(){
      console.log('click');
    });
  };

});
