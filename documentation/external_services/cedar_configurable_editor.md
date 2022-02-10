
The CEDAR Embeddable Editor allows arbitrary forms to be embedded into
Dryad. These forms are template-driven, and allow us to gather descriptive
metadata for particular types of studies.

Documentation
=============

Documentation available here:
https://docs.cee.staging.metadatacenter.org/

And a demo interactive deployment of the editor can be found here:
https://demo.cee.staging.metadatacenter.org/


Installation
==============

The old (Angular) version is at the following link:
https://component.metadatacenter.org/cedar-embeddable-editor/cedar-embeddable-editor-2.6.17.js
- This version depends on Angular to connect the config file with the editor.

The non-Angular version is available at: 
https://github.com/metadatacenter/cedar-cee-demo-generic/tree/develop
with a JS file called `cedar-embeddable-editor-2.6.18-SNAPSHOT.js`

runs with
- cd ~/lib/cedar-cee-demo-generic
- php -S localhost:8009
- http://localhost:8009


Configuration
==============

Config file: cee-config.json

The demo page adds an event listener for the event WebComponentsReady. When this
event is fired, the config file is injected into the cedar-embeddable-editor
component using a method called loadConfigFromURL.

Templates are stored at a URL specified by
`sampleTemplateLocationPrefix`. Within this URL, every template has a number,
then the template itself is called `template.json`, so the full URL will be
something like
https://component.metadatacenter.org/cedar-embeddable-editor-sample-templates/53/template.json

All the templates made public via the component server are available on GitHub
https://github.com/metadatacenter/cedar-component-distribution/tree/master/cedar-embeddable-editor-sample-templates


Templates
==========

The template controls the types of fields that are displayed and how/whether
they are tied to an ontolgy.

Field type
- _ui/inputType

Field values/ontology
- _valueConstraints/branches/uri


Styling
=======

There is a sample empty CSS template for the CEE (https://github.com/metadatacenter/cedar-cee-demo-generic/blob/develop/assets/css/styles.css).


How it works
==============

webcomponents-loader.js determines whether the browser fully supports ES6, and
adds polyfills if needed. When it is done, it fires the event
WebComponentsReady.

Retrieves controlled terms directly from CEDAR’s production terminology
server. This is related to the question you asked in our last meeting. You
currently don’t need any CEDAR apiKey to make those calls.
