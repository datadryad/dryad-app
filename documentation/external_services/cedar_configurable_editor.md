
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

Config file: `public/cedar-embeddable-editor/cee-config.json`

- The config file is publicly available. The user's browser will
  download it when initiating the editor.
- We could move this config into a more protected location, but it doesn't seem
  necessary, since every user would have access to it anyway.
- When the description page triggers config loading, the config file is injected into the
  `cedar-embeddable-editor` component using a method called `loadConfigFromURL`.


Templates
---------

In Dryad, templates are configured in `app_config.yml`. The numbers in the
templates reference the numbered config files in
`public/cedar-embeddable-editor/`. 

For the CEDAR editor, templates are stored at a URL specified by
`sampleTemplateLocationPrefix`. Within this URL, every template has a number,
then the template itself is called `template.json`, so the full URL will be
something like
https://component.metadatacenter.org/cedar-embeddable-editor-sample-templates/53/template.json

All the templates made public via the component server are available on GitHub
https://github.com/metadatacenter/cedar-component-distribution/tree/master/cedar-embeddable-editor-sample-templates

The template controls the types of fields that are displayed and how/whether
they are tied to an ontolgy.

Field type
- _ui/inputType

Field values/ontology
- _valueConstraints/branches/uri


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
