
/*
 This is for overriding the jquery-ujs standard javascript popup for accessibility since they said it was confusing.  It is
 used all over in our app with "are you sure?" type questions before deleting an item.

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

  The only way I could really get it to work this way is to trigger the allowAction twice.  The first time it pops the dialog open.
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

  // Set the Are you sure? dialog text.
  $('#railsConfMsg').text(message);

  // Setup promise of what happens with dialog
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
      dlgRemoveHandlers();
    });

    const nBtn = document.getElementById('railsConfirmDialogNo');
    const nHandler = nBtn.addEventListener("click", () => {
      resolve(false);
      document.getElementById('railsConfirmDialog').close();
      dlgRemoveHandlers();
    });

    const cBtn = document.getElementById('railsConfirmDialogClose');
    const cHandler = cBtn.addEventListener("click", () => {
      resolve(false);
      document.getElementById('railsConfirmDialog').close();
      dlgRemoveHandlers();
    });

    const dlgRemoveHandlers = function() {
      yBtn.removeEventListener('click', yHandler, false);
      nBtn.removeEventListener('click', nHandler, false);
      cBtn.removeEventListener('click', cHandler, false);
    }
  });

  // IDK, what the rails.fire does exactly, in context of the whole jquery_ujs library, but keeping it in the flow for the dialog
  // since I don't want to break something else that relies on it somehow and the original method used it for some kind of lifecycle.
  if ($.rails.fire(element, 'confirm')) {  // the first fire happens when dialog opens
    promise.then(result => {
      $.rails.fire(element, 'confirm:complete', [result]); // this fire happens when the dialog completes/closes
      if (result === true) {
        element.data('skipAreYouSure', true); // add a data item to the element for ignoring the dialog next it is triggered
        const elType = element[0].tagName.toLowerCase();
        if (elType === 'form') {
          element.submit();
        }else{
          element.click();
        }
      }
    });
  }
  return false;
};
