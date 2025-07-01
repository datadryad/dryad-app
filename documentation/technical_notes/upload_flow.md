File uploads to S3 temporary storage
====================================

Upload page
-----------

The upload page allows files to be uploaded directly ("Choose files") or by reference ("Enter URLs").

See `app/controllers/stash_engine/resources_controller.rb` for the controller. It sets up basics like the
@resource and information about the file model being used.

Some page rendering is at `app/views/stash_engine/resources/` and with the name
of the controller action as the template. Much of the functionality is handed off to React
component `UploadFiles`.

Evaporate.js for managing file transfers
----------------------------------------

- It is a library for creating presigned URLs and uploading to S3
- Needed for large uploads and splitting into multiple parts
- It is an NPM library that was difficult to load into a normal page in the current Rails system, but will likely be easier
  to include dependent libraries in React and with NPM.
- Using a Javascript library called *Browserify* to put the needed Javascript libraries into our environment. See `evaporate_init.js`
  - Also includes some code to sanitize bad filenames that we don't want to send to S3 in that file
  - package.json includes the following script line. `"build": "browserify evaporate_init.js -o app/assets/javascripts/stash_engine/evaporate_bundle.js"`
  - That allows `npm run build` to install the browserify componants.
- *evaporate.js* creates and initializes a new instance of evaporate.js
  - In order to work, evaporate.js requires a server URL that signs uploads. This is at a "presign_url_path" which is
    polymorphic and depends on which upload type. The code is common and included in both controllers. See the file
    `app/controllers/stash_engine/concerns/uploadable.rb`. By including this file in both different
    controllers, they share the same methods.
  - The "presign_upload" method in the `uploadable.rb` creates the signing for evaporate.js
  - `complete_path` is what AJAX gets called when a file is complete.
  - `s3_directory` defines where the file will go in our S3 bucket and is determined by our configuration and rails method.
  - Pulls out some settings from our rails configuration at `config/app_config.yml` . Note that the API key should **never** be
    be exposed in the client side javascript, but only used inside of the Rails controller where it generates presigned
    urls since the secret should always be kept secret from the client.
- Other javascript. Other javascripts can be loaded as part of the application for every page and most live under
  `app/assets/javascripts/stash_engine` . These files are combined and minified and cached forever
  and loaded for every page in our current config, I think. `resources.js` and `file_uploads.js` may be relevant for some
  other events on the page.
 
