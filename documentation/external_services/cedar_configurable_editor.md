
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

Non-Dryad tester
------------------

There is a version available at: 
https://github.com/metadatacenter/cedar-cee-demo-generic/tree/develop
with a JS file called `cedar-embeddable-editor-2.6.18-SNAPSHOT.js`

runs with
- cd ~/lib/cedar-cee-demo-generic
- php -S localhost:8009
- http://localhost:8009

Dryad tester
-------------

Currently, Dryad has a demonstration of the editor running in these places to
demonstrate different loading:
- `our_misison` page (Full debugging/config info)
- submission system description page (Minimal "normal" setup)
- submission system upload page (using React)

Before running within Dryad, we ran:
`npm install @webcomponents/webcomponentsjs`
It is unclear whether this is strictly required. The webcomponentsjs library
mostly contains polyfills for backwards compatibility. The editor may work fine
without it.


Configuration
==============

Config file: `public/cedar-embeddable-editor/cee-config.json`

- The config file is publicly available. The user's browser will
  download it when initiating the editor.
- We could move this config into a more protected location, but it doesn't seem
  necessary, since every user would have access to it anyway.

When the demo page triggers config loading, the config file is injected into the
cedar-embeddable-editor component using a method called loadConfigFromURL.


Templates
---------

Templates are stored at a URL specified by
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

There is a sample empty CSS template for the CEE (https://github.com/metadatacenter/cedar-cee-demo-generic/blob/develop/assets/css/styles.css).


How it works
==============

webcomponents-loader.js determines whether the browser fully supports ES6, and
adds polyfills if needed. When it is done, it fires the event
WebComponentsReady.

Retrieves controlled terms directly from CEDAR’s production terminology
server. This is related to the question you asked in our last meeting. You
currently don’t need any CEDAR apiKey to make those calls.
