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

/*
 See https://dev.to/boyum/creating-a-simple-confirm-modal-in-vanilla-js-2lcl which gives useful example of using confirm modal.
 https://derk-jan.com/2020/10/rails-ujs-custom-confirm/ gives an example of replacing the allowAction, in jQuery-ujs, but
 it seems pretty naive and uses global variables and also doesn't take into account all the different types of elements
 that allowAction can operate on.

 From reading all the jquery-ujs source, it is called from these below, first line in group is what triggers, the second
 line in group gives the line number and shows how it operates on links (2 types), buttons (2 types), forms.

  $document.on('click.rails', rails.linkClickSelector
  429 if (!rails.allowAction(link)) return rails.stopEverything(e);

  $document.on('click.rails', rails.buttonClickSelector
  454 if (!rails.allowAction(button) || !rails.isRemote(button)) return rails.stopEverything(e);

  $document.on('change.rails', rails.inputChangeSelector,
  470 if (!rails.allowAction(link) || !rails.isRemote(link)) return rails.stopEverything(e);

  $document.on('submit.rails', rails.formSubmitSelector,
  482 if (!rails.allowAction(form)) return rails.stopEverything(e);

  $document.on('click.rails', rails.formInputClickSelector,
  527 if (!rails.allowAction(button)) return rails.stopEverything(event);

  Unfortunately it's icky to move it out of a synchronous call (Javascript confirm that the accessibility people hate
  to an asyncronous call that does "modal" dialog in same web page.

  The only way I could really get it to work this way is to trigger the allowAction twice.  The first time it pops the dialog.
  If it's accepted (promise.then result is true), then set a data element on the item to indicate to skipAreYouSure (value true).

  When it gets called again (with re-triggering the original event again), then it will see that skipAreYouSure is set, it
  unsets it and proceeds to the action without prompting this time (by returning true instead of false).
 */
$.rails.allowAction = function(element) {
  const message = element.data('confirm');

  if (!message || element.data('skipAreYouSure')) {
    element.removeData('skipAreYouSure');
    return true;
  }

  $('#railsConfMsg').text(message);

  console.log("in confirmer");



  const promise = new Promise((resolve, reject) => {
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

  if ($.rails.fire(element, 'confirm')) {
    promise.then(result => {
      console.log("response to dialog " + result);
      console.log(element);
      console.log($.rails.fire);
      $.rails.fire(element, 'confirm:complete', [result]);
      if (result === true) {
        element.data('skipAreYouSure', true);
        element.click();
      }
    });
  }
  return false;
  // return confirm(message);
};

/* For 'data-confirm' attribute:
     - Fires `confirm` event
     - Shows the confirmation dialog
     - Fires the `confirm:complete` event

     Returns `true` if no function stops the chain and user chose yes; `false` otherwise.
     Attaching a handler to the element's `confirm` event that returns a `falsy` value cancels the confirmation dialog.
     Attaching a handler to the element's `confirm:complete` event that returns a `falsy` value makes this function
     return false. The `confirm:complete` event is fired whether or not the user answered true or false to the dialog.
  */
/*
allowAction: function(element) {
  var message = element.data('confirm'),
      answer = false, callback;
  if (!message) { return true; }

  if (rails.fire(element, 'confirm')) {
    try {
      answer = rails.confirm(message);
    } catch (e) {
      (console.error || console.log).call(console, e.stack || e);
    }
    callback = rails.fire(element, 'confirm:complete', [answer]);
  }
  return answer && callback;
},

fire: function(obj, name, data) {
  var event = $.Event(name);
  obj.trigger(event, data);
  return event.result !== false;
}
*/

