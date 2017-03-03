function loadEmbargoes() {
  $( '#datepicker' ).datepicker({
    changeMonth: true,
    changeYear: true,
    minDate: 0,
    dateFormat: 'MM-dd-yy',
    onClose: function(strDate, datepicker) {
      // According to the docs this situation occurs when
      // the dialog closes without the user making a selection
      if(strDate == "") {
        return;
      }
      // updated value at this point.
      $(this).parent().trigger('submit.rails');
    }
  });

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
};