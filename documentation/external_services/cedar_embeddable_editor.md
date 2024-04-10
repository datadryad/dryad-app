
CEDAR Embeddable Editor
=======================

The CEDAR Embeddable Editor (CEE) allows arbitrary forms to be embedded into
Dryad. These forms are template-driven, and allow us to gather descriptive
metadata for particular types of studies.


Documentation
-------------

Project documentation available here:
 - https://docs.cee.staging.metadatacenter.org/
 - https://github.com/metadatacenter/cedar-embeddable-editor/
 - https://github.com/metadatacenter/cedar-embeddable-editor/tree/develop

And a demo interactive deployment of the editor can be found at
https://demo.cee.staging.metadatacenter.org/

### Templates

Templates control the fields that are displayed and how and whether
they are tied to an ontolgy. Information about CEDAR templates id available at
https://more.metadatacenter.org/tools-training/cedar-template-tools

### Non-Dryad tester

There is a CEE testing version available at:
https://github.com/metadatacenter/cedar-cee-demo-generic/tree/develop

Follow the directions there to run the tester.


Dryad implementation
====================

The CEE is implemented in production on Dryad for Cognitive Neuroscience datasets,
specifically. Users submitting a dataset in this domain are invited to use a specifically
selected CEDAR template in this subject area. This implementation can be expanded to
match other subject areas with specific templates.

Dryad has also implemented the CEE with multiple templates, in which the user has the
ability to select their own desired template from all of those available on Dryad. This can
be set up on the Dryad sandbox for testing.


Output in dataset
-----------------

When a user seelcts a CEDAR template and begins to complete it, their entries in the templated form
are saved to the Dryad database in a compatible JSON format.

The resulting JSON file is available in the completed and published dataset as `DisciplineSpecificMetadata.json`.


Templates
---------

In Dryad, templates are configured in `config/app_config.yml`. The numbers in the
templates reference the template CEDAR ID and match the directories in 
`public/cedar-embeddable-editor/templates/`. 

Templates are stored at a URL specified by `sampleTemplateLocationPrefix`. 
Within this URL, every template has a directory matching its ID, and the template itself
is called `template.json`. So the full URL will be something like
https://datadryad.org/cedar-embeddable-editor/templates/7479dcb2-2c2f-44c8-953d-507c8b52c06a/template.json

### Obtaining new templates

We store templates in the Dryad codebase, allowing us to control when they are
updated. To obtain a template from CEDAR:

1. Get the CEDAR ID for the template you want to download (the template maintainer should give you this)
2. Login to CEDAR at https://cedar.metadatacenter.org/ -- you can use any method
   to login, but ORCID is always good!
3. Go to your user profile page and find your API key
4. Download the template using a command like this:
   `curl -H "Authorization: apiKey <your-API-key-here>" "https://repo.metadatacenter.org/templates/<template-ID-here>"`
5. Create a new directory in `public/cedar-embeddable-editor/templates/` matching the CEDAR ID, and save the `template.json` file there.
6. Ensure that the Dryad `config/app_config.yml` references the new template, using the CEDAR ID.


Components
----------

1. Which CEDAR templates are available on each Rails environment is configured in our APP_CONFIG
2. CEDAR configuration and saving methods are in `app/controllers/cedar_controller.rb`
3. The check for loading the currently live Cognitive Neuroscience template is handled by the `cedar_check` in the `StashDatacite::MetadataEntryPagesController` and related views
4. The CEE is loaded on the page through a REACT component: `app/javascript/react/components/MetadataEntry/Cedar.jsx`

### Configuration

The CEE requires a configuration file. These files are generated
dynamically by the `app/controllers/cedar_controller.rb`, because they must include the ID of the
template that the user is requesting.

When the CEDAR React component opens the modal dialog:
1. The editor is initialized using a method called `loadConfigFromURL`.
2. The URL passed in is the path to `cedar_controller.json_config`, with a parameter
   indicating the template ID.
3. The editor receives the template ID in the configuration, and uses it to construct
   a URL to retrieve the template file out of the `/cedar-embeddable-editor/` directory.


Installing updates
------------------

The CEE is updated regularly. New versions can be downloaded from (github)[https://github.com/metadatacenter/cedar-embeddable-editor]. To install a new version:

1. Download or pull the new version files
2. Enter the project directory and run `npm install`
3. Follow the CEE instructions for [Building the Webcomponent](https://github.com/metadatacenter/cedar-embeddable-editor?tab=readme-ov-file#building-the-webcomponent)
4. In the final `cedar-embeddable-editor.js` file, update the CEE font to the font used on the Dryad website. (Universally replace `Roboto` with `KievitWeb`)
5. Replace the file in `public/cedar-embeddable-editor/` with the new `cedar-embeddable-editor.js`
