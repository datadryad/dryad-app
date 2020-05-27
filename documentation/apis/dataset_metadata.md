
Dataset Metadata
=================

Datasets in the Dryad API consist largely descriptive metadata
inspired by the
[DataCite Metadata Schema](https://schema.datacite.org/). However,
some of the fields have different names, and there are some
Dryad-specific additions.

Minimal Metadata
=================



Complete Metadata
=================

To see the dataset fields and options in use, see the [sample dataset object](sample_dataset.json).

Dataset options
-----------------

Journal administrators that are creating a dataset on behalf of
another user *must* include the `publicationISSN` field to indicate
the associated journal. They *may* also include `publicationName` and `manuscriptNumber`.

Superusers have access to some extra options that control a dataset's behavior:
- `skipDataciteUpdate` - If true, doesn't send any requests to DataCite when registering the dataset. This is useful when the dataset already has a DOI, which is present in the metadata being submitted.
- `skipEmails` - If true, prevents emails from being sent to users on submission. Prevents emails regardless of whether the submission is successful or an error. Also stopps the emails that ask co-authors to register their ORCID. Does *not* stop the internal emails that are sent to Dryad admins if there is a submission error.
- `preserveCurationStatus` - If true, prevents Dryad from automatically setting the curation status to "submitted". This is useful when the dataset already has a curation status that will be set in a later API call.
- `loosenValidation` - Allows a dataset to be processed even if author information is incomplete (e.g., missing affiliations), or if the abstract is missing. It does still perform some basic validation of the dataset.

The above settings get carried with a dataset into future API submissions, but the UI resets all of these values to `false` so that people can't avoid being good research citizens when they manually update their datasets. These settings are hidden when they're in the default (false) state to keep people from seeing them and trying to set them (since most people can't set them).
