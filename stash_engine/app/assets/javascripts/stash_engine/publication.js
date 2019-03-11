function loadDatepicker(days) {

  // set correct option when people click into mm/dd/yyyy or other things
  $('.js-embargo-select').click(function() {
    $("#future_button").prop("checked", true);
    setEmbargoState();
  });
  // when changed from today to future or opposite update state and submit the form
  $('#future_button,#today_button').click(function() {
    setEmbargoState();
    $('#embargo_form').submit();
  });
  $('#mmEmbargo,#ddEmbargo,#yyyyEmbargo').blur(function() {
    $('#embargo_form').submit();
  });

  $( '#date' ).datepicker({
    changeMonth: true,
    changeYear: true,
    minDate: 0,
    maxDate: '+' + days + 'D',
    dateFormat: 'mm/dd/yy',
    onClose: function(strDate, datepicker) {
      // According to the docs this situation occurs when
      // the dialog closes without the user making a selection
      if(strDate == "") {
        return;
      }
      $('#ddEmbargo').val(strDate.split('/')[1]);
      $('#mmEmbargo').val(strDate.split('/')[0]);
      $('#yyyyEmbargo').val(strDate.split('/')[2]);
      // updated value at this point.
      $(this).parent().trigger('submit.rails');
    }
  });

  $("#datepicker").click(function ( event ) {
    event.preventDefault();
    $('#date').datepicker("setDate", new Date( $('#yyyyEmbargo').val(), $('#mmEmbargo').val() - 1, $('#ddEmbargo').val() ) )
    $("#date").datepicker("show");
  });

  /*
  $( '#date_options' ).on('change', function () {
    new_value = this.value;
    // Show the release date label and datepicker
    if(new_value == "today") {
      $('#datepicker').val('');
      $('.release_date').hide();
      $('#datepicker').datepicker('setDate', new Date()).parent().trigger('submit.rails');
      $('#datepicker').val('');
    }
    else {
      $('#datepicker').val('');
      $('.release_date').show();
    }
  });
  */
};

function disableDatepicker(){
  $('#ddEmbargo').prop('disabled', true);
  $('#mmEmbargo').prop('disabled', true);
  $('#yyyyEmbargo').prop('disabled', true);
  $('.c-pubdate__radio').prop('disabled', true);
  $('#datepicker').prop('disabled', true);
}

// switch the mm/dd/yyy to readonly and back, probably not needed.
function setEmbargoState(){
  if($('#today_button').is(':checked')){
    $('.js-embargo-select').attr( "readonly", "readonly" );
  }else{
    $('.js-embargo-select').removeAttr('readonly');
  }
}