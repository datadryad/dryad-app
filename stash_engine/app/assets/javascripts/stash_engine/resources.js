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
          removeDuplicateFilename(data.files[0].name); // removes existing duplicate before adding again
          $('#upload_list').append(data.context);
          $('#confirm_text_upload, #upload_all').show();
          confirmToUpload();
          // binding remove link action
          $('.js-remove_link').click( function(e){
            e.preventDefault();
            // $('.js-remove_link').parent().parent().find('.js-filename').text()
            var fn = $(e.target).parent().parent().find('.js-filename').text();
            var row = $(e.target).closest('.js-unuploaded').attr('id');
            // e.target.parentNode.parentNode.remove();

            // maybe restore the old file if it is there and was overwritten
            $.ajax({
              url: removeUnuploadedFileUploadPath(),
              type: 'POST',
              dataType: 'script',
              data: {
                _method: 'PATCH',
                filename: fn,
                row_id: row,
                // authenticity_token: '<%= form_authenticity_token %>',
                format: 'js'
              }
            });
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
    if(overTotalSize(totalSize())){
      e.preventDefault();
      alert('You are attempting to create a version with more than ' + formatSizeUnits(maxTotalSize()) +
          '.  Please remove some files to get under this limit for total size.');
      return false;
    }
    if(overFileSize(largestSize())) {
      e.preventDefault();
      alert('You are attempting to upload a file larger than ' + formatSizeUnits(maxFileSize()) + '.  Please remove any files larger than this limit and try again.');
      return false;
    }
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

/* The size is complicated since we are showing rows in many states in the same table with div classes around rows:
   .js-copied_file    --    A file previously uploaded from an earlier version of dataset with entry in database
   .js-unuploaded     --    A file dropped but does not exist on server side and hasn't been uploaded yet
   .js-created_file   --    A file that has been dropped and uploaded to the server in this version
   .js-deleted_file   --    A file the user wants to remove from this version but existed previously
              Note that files newly uploaded (or not uploaded yet) and deleted disappear from the table forever

   I believe files dropped and that match a file already in the table will make the previous file disappear since
   we cannot have duplicate filenames and it would be very confusing to list two files with same names.  There
   may need special handling after uploading for these files which are replacements.  Not sure how deletion of
   these files works.

   Total size would be copied, un-uploaded (drag'n'dropped) and created files, assuming only one of each unique filename.
 */
function totalSize(pre){
  pre = typeof pre !== 'undefined' ? pre : '#upload_list'; // set the default jquery prefix for this table
  nums = $(pre + ' .js-created_file .js-hidden_bytes,' +
          pre + ' .js-copied_file .js-hidden_bytes,' +
          pre + ' .js-unuploaded .js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
  var total = 0;
  $.each(nums, function( index, value ) {
    total += value;
  });
  return total;
}

// Just the new stuff to be uploaded into this version
function uploadSize(pre){
  pre = typeof pre !== 'undefined' ? pre : '#upload_list'; // set the default jquery prefix for this table
  nums = $(pre + ' .js-created_file .js-hidden_bytes,' +
          pre + ' .js-unuploaded .js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
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
    // if files are waiting for upload
    $('#upload_tweaker_head').removeClass('t-upload__choose-heading').addClass('t-upload__choose-heading--active');
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").click(function(e) {
      e.preventDefault();
      alert('You have files that have not been uploaded, please upload them or remove them from your list before continuing.');
    });
    if(uploadInProgress) {
      $('#cancel_all').show();
      undoConfirmUpload();
      $('#confirm_text_upload, #upload_all').hide();
      $('#revert_all').hide();
    }
  }else{
    // files are already uploaded or there are none
    $('#cancel_all').hide();
    $('#upload_tweaker_head').removeClass('t-upload__choose-heading--active').addClass('t-upload__choose-heading');
    undoConfirmUpload();
    $('#confirm_text_upload, #upload_all').hide();
    $("a[class^='c-progress__tab'], #describe_back, #proceed_review").unbind( "click" );
    uploadInProgress = false;
    updateRevertState();
  }
  updateUiStates();
}

function updateRevertState(){
  // console.log((new Date()).toISOString() + ' updating revert button state');
  but = $('#revert_all')
  if(versionNumber() == 1){
    but.hide();
  }else if($(".js-created_file,.js-deleted_file,.js-unuploaded").length > 0){
    but.show().prop("disabled", false).addClass('o-button__undo').removeClass('o-button__undo-disabled');
  }else{
    but.show().prop("disabled", true).addClass('o-button__undo-disabled').removeClass('o-button__undo');
  }
}

function largestSize(){
  nums = $('.js-hidden_bytes').map(function(){ return parseInt(this.innerHTML); });
  if(nums.length < 1){ return 0 };
  var sorted = nums.sort(function(a, b){return b-a});
  return sorted[0];
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
  $('#upload_total_all').text("Total: " + formatSizeUnits(totalSize()));
  $('#upload_in_version').text("New in this version: " + formatSizeUnits(uploadSize()));

  if(overTotalSize(totalSize()) || overFileSize(largestSize()) || overSubmissionSize(uploadSize())){
    $('#upload_total').removeClass().addClass('c-upload__total-size--warning');
  }else{
    $('#upload_total').removeClass().addClass('c-upload__total-size');
  }
  updateRevertState();
  // remove and notify if over size.
  if(overFileSize(largestSize())){
    // UI design says delete the large items automatically and swat the user with a rolled up newspaper.
    $("div[id^='not_uploaded_file_']").each(function( index ) {
      if(overFileSize($( this ).find('.js-hidden_bytes').text())){
        var name = $( this ).find('.js-filename').text();
        $('#over_single_size').append("<p>The file " + name  + " has been removed from your upload list since it is" +
            "larger than " + formatSizeUnits(maxFileSize()) + ".</p>");
        $( this ).remove();
        setTimeout(function(){
          $('#over_single_size').empty();
        }, 20000);
        updateUiStates();
      }
    });
  }

  if(overTotalSize(totalSize())){
    $('#over_files_size').show();
    undoConfirmUpload();
    $('#confirm_text_upload, #upload_all').hide();
  }else{
    $('#over_files_size').hide();
    if(!uploadInProgress && filesWaitingForUpload()) {
      $('#confirm_text_upload, #upload_all').show();
      confirmToUpload();
    }
  }

  if(overSubmissionSize(uploadSize())){
    $('#over_upload_size').show();
    undoConfirmUpload();
    $('#confirm_text_upload, #upload_all').hide();
  }else{
    $('#over_upload_size').hide();
    if(!uploadInProgress && filesWaitingForUpload()) {
      $('#confirm_text_upload, #upload_all').show();
      confirmToUpload();
    }
  }
}

/*  Function called when a new file is dropped and rids list of existing names that are exactly the same
    and issues warning that the previous file has been replaced.
 */
function removeDuplicateFilename(fn){
  dups = $('.js-filename').filter(function( index ) {
    return (fn == $(this).text());
  });
  // get row element with these classes and delete it.
  if(dups.length > 0) {
    dups.parents('.js-copied_file,.js-unuploaded,.js-created_file,.js-deleted_file').remove();
    $('#over_single_size').append("<p>Your previous file <strong>" + fn +
        "</strong> has been replaced in your upload list with a newer file with the same name.</p>");
    /* setTimeout(function () {
      $('#over_single_size').empty();
    }, 20000); */
    $('#confirm_text_upload, #upload_all').show();
    confirmToUpload();
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

function undoConfirmUpload() {
  $('#confirm_to_upload').attr('checked', false);
  $('#upload_all').attr('disabled', true);
}

// **********************************************************************************
// end Javascript for FileUpload page.  This section was only for FILES, not MANIFEST
// **********************************************************************************

// ********
// Functions for both file and manifest sections
// ********

// sets both HTML file tables (manifest & upload) back to the DB state
function resetFileTablesToDbState(){
  $.ajax({
    url: showFilesResourcePath(),
    type: 'GET',
    dataType: 'script',
    data: {
      // authenticity_token: '<%= form_authenticity_token %>',
      format: 'js'
    }
  });
}
// ********
// END Functions for both file and manifest sections
// ********

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
  resetFileTablesToDbState();
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