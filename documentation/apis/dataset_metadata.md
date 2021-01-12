
Dataset Metadata
=================

Datasets in the Dryad API consist largely descriptive metadata
inspired by the
[DataCite Metadata Schema](https://schema.datacite.org/). However,
some of the fields have different names, and there are some
Dryad-specific additions.

To see the dataset fields and options in use, see the [sample dataset object](sample_dataset.json).

Minimal Metadata
=================

The minimal fields for a dataset are:
- `title` - The title of the dataset. This title may reference an
  associated article, or it may describe only the data.
- `authors` - A list of authors for the dataset. At minimum, each
  author must contain `firstName`, `lastName`, `email`, and `affiliation`.
- `abstract` - A short description of the dataset, similar to the
  abstract of an article. HTML markup is acceptable in this field.

An example of minimal metadata is used in the
[submission API documentation](submission.md).

Note that a dataset may be initially created with some of the minimal
metadata omitted (e.g., to obtain a stub dataset object before adding
files). However, all of the minimal metadata must be present in order
to submit the dataset for curation.

Authors
==========

In addition to the minimal metadata, each author may include:
- `orcid` - The ORCID identifier associated with the author. 
- `affiliationROR` or `affiliationISNI` - A formal identifier for the
  author's affilation. If one of these is present, it will take
  precedence over an `affiliation` field, and in this case, the
  `affiliation` field is not required. 

Descriptive fields
==================

Other fields with descriptive metadata include:
- `relatedWorks` - Relationships to other objects may be specified by
  giving a `relationship` and identifier information. The allowed
  values for `relationship` are: `undefined`, `article`, `dataset`, `preprint`,
  `software`, `supplemental_information`
- `funders` - Funding organizations and award numbers may be
  specified. 
- `methods` - Description of methods for collecting and processing the
  data. HTML markup is acceptable in this field.
- `usageNotes` - Instructions for using the data. HTML markup is acceptable in this field. 
- `keywords` - A list of subject keywords associated with the
  dataset. These are *not* restricted by a controlled vocabulary.
- `locations` - Any number of places, points, or bounding boxes
  associated with the dataset.

Journal/Article relationships
=============================

If the dataset is associated with a journal article, these fields may
be included:
- `publicationISSN` - The ISSN of the associated journal.
- `publicationName` - The name of the associated journal. If both this
  and `publicationISSN` are present, the `publicationISSN` will take
  precedence. If only the name is present, Dryad will attempt to look
  up the ISSN by matching with existing journals in our system.
- `manuscriptNumber` - The internal manuscript number assigned to an
  associated article before publication. For journals that integrate
  their publication process with Dryad, the `manuscriptNumber` is
  required to coordinate publication of the dataset and article.

Journal administrators that are creating a dataset on behalf of
another user *must* include the `publicationISSN` field to indicate
the associated journal. They *may* also include `publicationName` and `manuscriptNumber`.

Administrator options
======================

The fields in this section are only availble to users with
appropriate permissions. Dryad superusers may use any of these fields,
while administrators of Dryad's member institutions/journals are
allowed to use a subset of
them. [Contact Dryad](mailto:help@datadryad.org) to verify that you
have access to the fields that are appropriate for your needs:
- `identifier` - This may be used to declare a DOI for the dataset
  being created. It is typically used when a dataset was originally
  created in a separate system, and is being replicated to Dryad.
- `userId` - This field may be used if the API user is submitting the
  dataset on behalf of another user. The value of the field may be
  either a Dryad user ID (obtained through the `/users` API), or an
  ORCID. If it is an ORCID, it should match the ORCID supplied with
  one of the dataset authors.

Rarely-used options
-------------------

Superusers have access to some extra options that control a dataset's
behavior:
- `invoiceId` - Indicates the ID of an invoice that has already been
  applied to this dataset. Dryad will not attempt to generate a
  separate invoice.
- `skipDataciteUpdate` - Defaults to false. If true, doesn't send any
  requests to DataCite when registering the dataset. This is useful
  when the dataset already has a DOI, which is present in the
  `identifier` field.
- `skipEmails` - Defaults to false. If true, prevents emails from
  being sent to users on submission. Prevents emails regardless of
  whether the submission is successful or an error. Also suppresses
  the emails that ask co-authors to register their ORCID. Does *not*
  stop the internal emails that are sent to Dryad admins if there is a
  submission error.
- `preserveCurationStatus` - Defaults to false. If true, prevents
  Dryad from automatically setting the curation status to
  "submitted". This is useful when the dataset already has a curation
  status that will be set in a later API call.
- `loosenValidation` - Defaults to false. Allows a dataset to be
  processed even if author information is incomplete (e.g., missing
  affiliations), or if the abstract is missing. It does still perform
  some basic validation of the dataset. This should only be used when
  datasets are being replicated from another system and it is not
  feasible to provide complete metadata.

The above settings get carried with a dataset into future API
submissions, but Dryad's web interface resets these values to `false` (except
`invoiceId`). This forces the "normal" behavior when users are editing
individual datasets through the web interface.
