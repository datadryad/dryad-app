// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery-ui
//= require ckeditor/init
//= require_tree .

console.log($.rails.allowAction);

$.rails.confirm = function(message) {
  console.log("in confirmer");

  // see https://dev.to/boyum/creating-a-simple-confirm-modal-in-vanilla-js-2lcl which gives useful example

  const prom = new Promise((resolve, reject) => {
    const somethingWentWrongUponCreation = !document.getElementById('railsConfirmDialog') ||
        !document.getElementById('railsConfirmDialogYes') ||
        !document.getElementById('railsConfirmDialogNo');

    if (somethingWentWrongUponCreation) {
      reject("Something is wrong with modal in html");
    }

    document.getElementById('railsConfirmDialog').showModal();

    const yBtn = document.getElementById('railsConfirmDialogYes');
    const yHandler = yBtn.addEventListener("click", () => {
      resolve(true);
      document.getElementById('railsConfirmDialog').close();
      yBtn.removeEventListener('click', yHandler, false);
    });

    const nBtn = document.getElementById('railsConfirmDialogNo');
    const nHandler = nBtn.addEventListener("click", () => {
      resolve(false);
      document.getElementById('railsConfirmDialog').close();
      nBtn.removeEventListener('click', yHandler, false);
    });
  });

  prom.then(result => {
    console.log(result);
    return result;
  });
  console.log('after promise.then');
  // return confirm(message);
};
