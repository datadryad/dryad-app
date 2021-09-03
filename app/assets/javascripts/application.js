// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//

// This is renamed "papplication.js" because otherwise it clobbers the one needed by
// geoblacklight to load it's junk and then nothing works.

//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

// see https://thelazylog.com/custom-dialog-for-data-confirm-in-rails/
//Override the default confirm dialog by rails
$.rails.allowAction = function(link){
  if (link.data("confirm") == undefined){
    return true;
  }
  $.rails.showConfirmationDialog(link);
  return false;
}
//User click confirm button
$.rails.confirmed = function(link){
  link.data("confirm", null);
  link.trigger("click.rails");
}
//Display the confirmation dialog
$.rails.showConfirmationDialog = function(link){
  /*
  var message = link.data("confirm");
  $.fn.SimpleModal({
    model: "modal",
    title: "Please confirm",
    contents: message
  }).addButton("Confirm", "button alert", function(){
    $.rails.confirmed(link);
    this.hideModal();
  }).addButton("Cancel", "button secondary").showModal();
   */
}
