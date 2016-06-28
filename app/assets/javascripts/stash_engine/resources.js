// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// this function triggered when dropped, but also continues the upload function

// *******************************
// Begin Javascript for FileUpload
// *******************************
$(function () {
    $('#fileupload').fileupload({
        dataType: 'script',
        add: function (e, data) {
          // what happens when added
          $('#no_chosen').hide();
          data.files[0]['id'] = generateQuickId();
          data.context = $(tmpl("upload-line", data.files[0]));
          $('#upload_list').append(data.context);
          $('#upload_all').show();
          // binding remove link action
          $('.js-remove_link').click( function(e){
            e.preventDefault();
            e.target.parentNode.parentNode.remove();
            updateTotalSize();
            updateButtonLinkStates();
          });

          // binding upload link click event
          $('#up_button_' + data.files[0].id ).click(function (e) {
            e.preventDefault();
            var inputs = data.context.find(':input');
            data.context.find(".js-bar").show();
            data.context.find(".js-cancel").show();
            data.context.find(".js-remove_link").hide();
            data.formData = inputs.serializeArray();
            data.submit();
          });


          // binding cancel link click event
          $('#cancel_' + data.files[0].id ).click(function (e) {
            e.preventDefault();
            data.abort();
            data.context.remove();
            e.target.parentNode.parentNode.remove();
            if(uploadInProgress) {
              $('.js-upload-it:first').click();
            };
            updateTotalSize();
            updateButtonLinkStates();
          })
          updateTotalSize(); // update the total size after drop, also.
          updateButtonLinkStates();
        },
        progress: function (e, data) {
          progress = parseInt(data.loaded / data.total * 100, 10);
          data.context.find('.js-bar').attr("value", progress)
        },
        done: function (e, data) {
            // $('#up_button_' + data.files[0].id).text('Upload finished.');
          updateTotalSize();
          updateButtonLinkStates();
        }
    });
});

$( document ).ready(function() {
  updateButtonLinkStates();
  $('#cancel_all').click(function() {
    uploadInProgress = false;
    $('.js-cancel:visible').click();
    $('#cancel_all').hide();
  });

  // start first js-upload-it line
  $('#upload_all').click( function(e){
    if(overTotalSize(totalSize())){
      e.preventDefault();
      alert('You are attempting to upload more than ' + formatSizeUnits(maxTotalSize()) + '.  Please remove some files to get under this limit.');
      return false;
    }
    if(overFileSize(largestSize())) {
      e.preventDefault();
      alert('You are attempting to upload a file larger than ' + formatSizeUnits(maxFileSize()) + '.  Please remove any files larger than this limit and try again.');
      return false;
    }
    uploadInProgress = true;
    $('.js-upload-it:first').click();
    updateButtonLinkStates();
  });
});


function generateQuickId() {
    return Math.random().toString(36).substring(2, 15) +
        Math.random().toString(36).substring(2, 15);
}

function formatSizeUnits(bytes) {
    if (bytes == 1){
        return '1 byte';
    }else if (bytes < 1000){
        return bytes + ' bytes';
    }

    var units = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    for (i = 0; i < units.length; i++) {
        if(bytes/Math.pow(10, 3*(i+1)) < 1){
            return (bytes/Math.pow(10, 3*i)).toFixed(2) + " " + units[i];
        }
    }
}

function totalSize(){
  nums = $('.js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
  var total = 0;
  $.each(nums, function( index, value ) {
    total += value;
  });
  return total;
}

function filesWaitingForUpload(){
  return ($("div[id^='not_uploaded_file_']").length > 0);
}

// update the button and navigation link states based on pending upload files
function updateButtonLinkStates(){
  if (filesWaitingForUpload()){
    $('#upload_all').show();
    $('#upload_tweaker_head').removeClass('t-upload__choose-heading').addClass('t-upload__choose-heading--active');
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").click(function(e) {
      e.preventDefault();
      alert('You have files that have not been uploaded, please upload them or remove them from your list before continuing.');
    });
    if(uploadInProgress) {
      $('#cancel_all').show();
      $('#upload_all').hide();
    }
  }else{
    $('#cancel_all').hide();
    $('#upload_tweaker_head').removeClass('t-upload__choose-heading--active').addClass('t-upload__choose-heading');
    $('#upload_all').hide();
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    uploadInProgress = false;
  }
}

function largestSize(){
  nums = $('.js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
  if(nums.length < 1){ return 0 };
  var sorted = nums.sort(function(a, b){return b-a});
  return sorted[0];
}

function updateTotalSize(){
  $('#upload_total').text("Total: " + formatSizeUnits(totalSize()));
}
// *****************************
// end Javascript for FileUpload
// *****************************