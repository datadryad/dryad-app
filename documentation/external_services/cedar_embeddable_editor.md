
The CEDAR Embeddable Editor allows arbitrary forms to be embedded into
Dryad. These forms are template-driven, and allow us to gather descriptive
metadata for particular types of studies.

Documentation
=============

Documentation available here:
https://github.com/metadatacenter/cedar-embeddable-editor/tree/develop
https://github.com/metadatacenter/cedar-cee-demo-generic/tree/develop
https://docs.cee.staging.metadatacenter.org/

And a demo interactive deployment of the editor can be found here:
https://demo.cee.staging.metadatacenter.org/


Non-Dryad tester
==================

There is a version available at:
https://github.com/metadatacenter/cedar-cee-demo-generic/tree/develop
with a JS file called `cedar-embeddable-editor-2.6.18-SNAPSHOT.js`

runs with
```
cd ~/lib/cedar-cee-demo-generic
php -S localhost:8009
http://localhost:8009
```
(The Dryad version should just work directly within our environment.)


Configuration
==============

The CEDAR editor requires a configuration file. These files are generated
dynamically by the `cedar_controller.rb`, because they must include the ID of the
template that the user is requesting.

When the Cedar component opens the modal dialog:
1. The editor is initialized using a method called `loadConfigFromURL`.
2. The URL passed in is the path to `cedar_controller.json_config`, with a parameter
   indicating the template ID.
3. The editor receives the template ID in the configuration, and uses it to construct
   a URL to retrieve the template file out of the `/cedar-embeddable-editor/` directory.


Templates
---------

In Dryad, templates are configured in `app_config.yml`. The numbers in the
templates reference the numbered config files in
`public/cedar-embeddable-editor/`. 

For the CEDAR editor, templates are stored at a URL specified by
`sampleTemplateLocationPrefix`. Within this URL, every template has a number,
then the template itself is called `template.json`, so the full URL will be
something like
https://datadryad.org/cedar-embeddable-editor/53/template.json

The template controls the types of fields that are displayed and how/whether
they are tied to an ontolgy.

Field type
- _ui/inputType

Field values/ontology
- _valueConstraints/branches/uri


Obtaining new templates
------------------------

We store templates in the Dryad codebase, allowing us to control when they are
updated. But templates are normally generated within the CEDAR website. To
obtain a template from CEDAR:

1. Get the CEDAR ID for the template you want to download (the template maintainer should give you this)
2. Login to CEDAR at https://cedar.metadatacenter.org/ -- you can use any method
   to login, but ORCID is always good!
3. Go to your user profile page and find your API key
4. Download the template using a command like this:
   `curl -H "Authorization: apiKey <your-API-key-here>" "https://repo.metadatacenter.org/templates/<template-ID-here>"`
5. Save the template in a numbered directory in Dryad like
   `public/cedar-embeddable-editor/123/template.json`
6. Ensure that the Dryad configuration references the new template, using the
   number of the directory that it was placed in.


Styling
=======

There is a sample empty CSS template for the CEE
(https://github.com/metadatacenter/cedar-cee-demo-generic/blob/develop/assets/css/styles.css).


Output
=======

- There is a demo `cedar_controller.rb` that can receive data from the demo form
fields. It gets the info, but there is a CRXF token error
- When users hit the "save" button, the form results are POSTed to the address
specified in the config file `dataSaverEndpointUrl`.
- The results are JSON


How it works
==============

webcomponents-loader.js (if used) determines whether the browser fully supports
ES6, and adds polyfills if needed. When it is done, it fires the event
WebComponentsReady.

Retrieves controlled terms directly from CEDAR’s production terminology
server. 
