// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// this function triggered when dropped, but also continues the upload function

// ********************************************************************************
// Begin Javascript for FileUpload page.  This section only for FILES, not MANIFEST
// ********************************************************************************
$(function () {
  // only do this stuff on the file upload page.
  if($('body.resources_upload').length < 1){
    return;
  }

    $('#fileupload').fileupload({
        dataType: 'script',
        add: function (e, data) {
          // what happens when added
          $('#no_chosen1').hide();
          data.files[0]['id'] = generateQuickId();
          data.context = $(tmpl("upload-line", data.files[0]));
          $('#upload_list').append(data.context);
          $('#confirm_text_upload, #upload_all, #upload_tweaker_head').show();
          $('#upload_complete').hide();
          confirmToUpload();

          // binding remove link action
          $('#not_uploaded_file_' + data.files[0]['id'] + ' .js-remove_link' ).click( function(e){
            e.preventDefault();
            $('#not_uploaded_file_' + data.files[0]['id']).remove();
            $('#upload_complete').hide();
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
            updateButtonLinkStates(); // for file upload method
          });
          updateButtonLinkStates(); // for file upload method
        },
        progress: function (e, data) {
          progress = parseInt(data.loaded / data.total * 100, 10);
          data.context.find('.js-bar').attr("value", progress)
        },
        done: function (e, data) {
          updateButtonLinkStates(); // for file upload method
        }
    });

  updateButtonLinkStates(); // for file upload method
  $('#cancel_all').click(function() {
    uploadInProgress = false;
    $('.js-cancel:visible').click();
    $('#cancel_all').hide();
  });

  // start first js-upload-it line
  $('#upload_all').click( function(e){
    uploadInProgress = true;
    $('.js-upload-it:lt(3)').click();
    updateButtonLinkStates(); // for file upload method
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

/* .js-unuploaded     --    A file dropped but does not exist on server side and hasn't been uploaded yet
   all other types are not needed on the JavaScript side because they're now handled on server with AJAX call.
   It's a separate table and we don't need to total it all in js now.
 */
function uploadSize(pre){
  pre = typeof pre !== 'undefined' ? pre : '#upload_list'; // set the default jquery prefix for this table
  nums = $(pre + ' .js-unuploaded .js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
  var total = 0;
  $.each(nums, function( index, value ) {
    total += value;
  });
  return total;
}

// update the waiting size in the staging list
function updateWaitingSize(){
  $('#size_in_upload').text('hi');
}

function filesWaitingForUpload(){
  return ($("div[id^='not_uploaded_file_']").length > 0);
}

// update the button and navigation link states based on pending upload files
function updateButtonLinkStates(){
  if (filesWaitingForUpload()){
    // if files are waiting for upload
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").click(function(e) {
      e.preventDefault();
      alert('You have files that have not been uploaded, please upload them or remove them from your list before continuing.');
    });
    if(uploadInProgress) {
      $('#cancel_all').show();
      $('#confirm_text_upload, #upload_all').hide();
    }
  }else{
    // files are already uploaded or there are none
    $('#cancel_all').hide();
    $('#confirm_text_upload, #upload_all, #upload_tweaker_head').hide();
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    uploadInProgress = false;
  }
  updateUiStates();
}

// updates the size and other UI state updates after changes to the file list
function updateUiStates(){
  // lock/unlock the manifest/file upload radio buttons depending if any modified files listed
  if($(".js-created_file,.js-deleted_file,.js-unuploaded").length > 0){
    disableUploadMethod();
  }else{
    enableUploadMethod();
    // resetFileTablesToDbState();
  }
}

function confirmToUpload(){
  // bind the upload button to the check box
  $('#confirm_to_upload').bind( "click", function() {
    //check if checkbox is checked
    if ($(this).is(':checked')) {
      $('#upload_all').removeAttr('disabled'); //enable input
    }
    else {
      $('#upload_all').attr('disabled', true); //disable input
    }
  });
}

// **********************************************************************************
// end Javascript for FileUpload page.  This section was only for FILES, not MANIFEST
// **********************************************************************************


// **********************************************************************************
// The items for  showing only upload method or manifest method
// **********************************************************************************
function setUploadMethodLockout(resourceUploadType){
  if(resourceUploadType == 'unknown') {
    enableUploadMethod();
  }else{
    disableUploadMethod()
  }
}

function disableUploadMethod(){
  if ($('#files_from_computer').prop('checked')) {
    $('#files_from_manifest').attr('disabled', true);
  }
  else {
    $('#files_from_computer').attr('disabled', true);
  }
}

function enableUploadMethod(){
  $('#files_from_manifest').attr('disabled', false);
  $('#files_from_computer').attr('disabled', false);
  // resetFileTablesToDbState();
}

function confirmToValidate(){
  // bind the upload button to the check box
  $('#confirm_to_validate').bind( "click", function() {
    //check if checkbox is checked
    if ($(this).is(':checked')) {
      $('#validate_files').removeAttr('disabled'); //enable input
    }
    else {
      $('#validate_files').attr('disabled', true); //disable input
    }
  });
}

// **********************************************************************************
// END The items for showing only upload method or manifest method
// **********************************************************************************

// **********************************************************************************
// The methods for the manifest workflow only
// **********************************************************************************

function addEventFewManyRows(){
  $('#show_10_files').click( function(e){
    e.preventDefault();
    $('#table_hider').hide();
    $('#show_10_files').hide();
    $('#show_all_files').show();
  });
  $('#show_all_files').click( function(e){
    e.preventDefault();
    $('#table_hider').show();
    $('#show_10_files').show();
    $('#show_all_files').hide();
  });
}

function hideLinksForFewRows(){
  if($('.c-manifest-table__row').length < 11){
    $('#show_10_files').hide();
    $('#show_all_files').hide();
  }
}

// takes the show10 and showAll visibility (t/f), be careful tricky since these are the links which have backwards
// logic.  ie.  show10 shows up when the table is showing all and showAll link shows when it's showing 10.
function tableStateRestorer(show10, showAll){
  if(show10 == showAll) {
    $('#show_10_files').hide();
    $('#show_all_files').show();
    show10 = false;
    showAll = true;
  }
  if(showAll){
    $('#show_all_files').show();
    $('#table_hider').hide();
  }else{
    $('#show_all_files').hide();
  }
  if(show10){
    $('#show_10_files').show();
  }else{
    $('#show_10_files').hide();
  }
  hideLinksForFewRows();
}

// **********************************************************************************
// END The methods for the manifest workflow only
// **********************************************************************************