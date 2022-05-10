How popups dialogs work
=========================

An overview of the steps in a popup dialog, using the user_role popup as an example:
- Containing page makes a form with the path for the popup: `user_role_popup_path(u.id)`
- Controller receives `role_popup` as a JS request, sets up any needed
  objects, and renders it (note that the @user object is often set up via a `:before_action`)
- The JS file `role_popup.js` makes the `genericModalDialog` visible and pulls
  in a partial that contains the specifics of this popup, `_admin_role_form.html.erb`
- The partial makes a form with the path for executing the results of the popup,
  `set_role_path`
- Controller receives `set_role`, performs the needed actions, and renders a JS result
- The JS result file `set_role.js` makes updates in the main page as needed,
  including hiding the popup.

