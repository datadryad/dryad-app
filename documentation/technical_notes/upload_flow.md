# The flow of how uploads to S3 work (2021-03-08)

## Current Upload Pages

There are 4 current upload pages two for data and two for software.  One page of *each* uploads files directly and one
just validates URLs live on the internet.  A lot of code is shared between the pages and is in shared files.

- Example url: https://dryad-dev.cdlib.org/stash/resources/3340/upload
  - Uploads files for data
  - upload_resource_path
  - stash_engine/resources#upload
- Example url: https://dryad-dev.cdlib.org/stash/resources/3340/upload_manifest
  - Validates URLs from server, live on the internet to be sure URL is valid and they exist
  - upload_manifest_resource_path
  - stash_engine/resources#upload_manifest
- Example url: https://dryad-dev.cdlib.org/stash/resources/3340/up_code
  - Uploads files for code
  - up_code_resource_path
  - stash_engine/resources#up_code
- Example url: https://dryad-dev.cdlib.org/stash/resources/3340/up_code_manifest
  - Validates URLs are accessible from our server, checks them live to the internet for validity
  - up_code_manifest_resource_path
  - stash_engine/resources#up_code_manifest

See `stash/stash_engine/app/controllers/stash_engine/resources_controller.rb` for the controller and it sets up basics like the
@resource and information about the file model being used.

Page rendering is at `stash/stash_engine/app/views/stash_engine/resources/` and with the name of the controller action as the
template (this is the Rails default to name views after the action).

## Shared component for rendering file uploads
The line below calls file upload component rendering.  See it under `stash_engine/file_uploads/_files_upload.html.erb`

`<%= render partial: 'stash_engine/file_uploads/files_upload', locals: { file: @file, resource: @resource, uploads: @uploads } %>`

Notice the bottom where it renders some dynamic javascript files into the page and they handle uploads.

```
// *****
  // *preview_to_page* does the annoying work of tracking files from dropping or selecting and displaying on page before uploading
  // *****
  <%= render partial: 'stash_engine/file_uploads/preview_to_page.js' %>

  // *****
  // *s3_upload* mostly focuses on uploading files in sequence by calling the evaporate library and displaying some changes
  // *****
  <%= render partial: 'stash_engine/file_uploads/s3_upload.js', locals: {resource: resource, file: file} %>

  // *****
  // *evaporate* configures and uses the library for uploading to S3 and returning a promise that it will upload or fail
  // *****
  <%= render partial: 'stash_engine/file_uploads/evaporate.js', locals: {resource: resource} %>
```

## About Evaporate.js
- It is a library for creating presigned URLs and uploading to S3
- Needed for large uploads and splitting into multiple parts
- It is an NPM library that was difficult to load into a normal page in the current Rails system, but will likely be easier
  to include dependent libraries in React and with NPM.
- Using a Javascript library called *Browserify* to put the needed Javascript libraries into our environment.  See `stash/stash_engine/evaporate_init.js`
  - Also includes some code to sanitize bad filenames that we don't want to send to S3 in that file
  - package.json includes the following script line.  `"build": "browserify evaporate_init.js -o app/assets/javascripts/stash_engine/evaporate_bundle.js"`
  - That allows `npm run build` to install the browserify componants.


## The javascript files from above (and a little info about controllers they call)
- *preview_to_page* -- This takes files that the user drags and drops and shows them on the page, but doesn't upload them yet.
  - Map `fUploading` that tracks the file object status while they're waiting for upload and adds additiona info like sanitized version
    of the filename.
  - The function `outputLine` is the HTML that gets generated and output to the page
  - Drag and drop
- s3_upload.js -- uploads the files one by one to S3 after being staged to view in the page and after the upload button is clicked
  - evaporateIt() is the main function that configures and does evaporate.js uploads to S3.
  - After uploads it may display errors or say it's complete.
  - After uploads, it refreshes the page with Rails UJS.  See the ajax call with url and dataType: 'script' (that is what
    ujs calls are rather than JSON.  It runs a script defined as the same name as the rails controller and action it calls
    in most cases).
- *evaporate.js* creates and initializes a new instance of evaporate.js
  - In order to work, evaporate.js requires a server URL that signs uploads.  This is at a "presign_url_path" which is
    polymorphic and depends on which upload type.  The code is common and included in both controllers.  See the file
    stash/stash_engine/app/controllers/stash_engine/concerns/uploadable.rb  .  By including this file in both different
    controllers, they share the same methods.
  - The "presign_upload" method in the `uploadable.rb` creates the signing for evaporate.js
  - `complete_path` is what AJAX gets called when a file is complete.
  - `s3_directory` defines where the file will go in our S3 bucket and is determined by our configuration and rails method.
  - Pulls out some settings from our rails configuration at `config/app_config.yml` .  Note that the API key should **never** be
    be exposed in the client side javascript, but only used inside of the Rails controller where it generates presigned
    urls since the secret should always be kept secret from the client.
- Other javascript.  Other javascripts can be loaded as part of the application for every page and most live under
  `stash/stash_engine/app/assets/javascripts/stash_engine` .  These files are combined and minified and cached forever
  and loaded for every page in our current config, I think.  `resources.js` and `file_uploads.js` may be relevant for some
  other events on the page.
  
## AJAX JSON and AJAX UJS (script) calls
- see *uploadable* as above for most common methods of the controllers
  - *presign_upload* presigns an upload for s3 and evaporate.js (renders plain data as evaporate.js uses)
  - *upload_complete* responds to the upload complete event and adds to database and returns json.
  - `file_uploads_controller` and `software_files_controller` have very little code of their own but mostly set up the file model
    (software or data) to use.  Most code is in `uploadable`.  This is similar with the models for these in the database where
    most code lives in a common concern that is included in both.
- Rendering of the file currently in the database is done by `uploadable#index`.  Notice it accepts *js* and renders the
  table from the file `stash_engine/file_uploads/index.js.erb` which may call other files.  This is typical UJS which calls
  AJAX with 'script' rather than json and allows rails to run Javascript including rendering views with javascript.
- This 15 minute tutorial is really useful in understanding how UJS works.  http://railscasts.com/episodes/205-unobtrusive-javascript?autoplay=true
  since I think this will help understand what is happening in the places we use UJS.  It does things in a consistent way which is
  AJAX script call --> controller action --> javascript template --> The javascript template may run javascript or render or replace
  part of DOM (maybe by rendering other Rails templates inside of javascript).

I hope this helps in understanding what is happening and is enough to get you starte.
