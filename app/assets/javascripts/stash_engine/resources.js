// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// ********************************************************************************
// Begin Javascript for informational and utility functions for file upload
// ********************************************************************************

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

function filesWaitingForUpload(){
  return ($("div[id^='not_uploaded_file_']").length > 0);
}

// it's hard to figure out the correct table view to show with a delete because client side state and server side link generation
// we have two in there (one for all files and one for page) and just need to show one
function showCorrectDelete(myId){
 if($('#show_10_files').length > 0){
   $('#destroy_all_' + myId).show();
 }else{
   $('#destroy_10_' + myId).show();
 }
}

// ********************************************************************************
// END Javascript for informational and utility functions for file upload
// ********************************************************************************