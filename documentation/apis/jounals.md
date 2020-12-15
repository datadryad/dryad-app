
Dryad Journal Module
======================

The journal module provides information about the journals associated
with Dryad. It runs from the old (v1) Dryad server, so its API is
separate from the newer [data-access API](https://datadryad.org/api/v2/docs/).

The journal module performs two functions:

1. Managing metadata about the journals and their workflows. (**This
   feature is deprecated.**)
2. Processing metadata emails from journals and updating the status of
   associated datasets.

Journal metadata
=================

Metadata about the journals and their workflows is stored in Dryad's
`StashEngine::Journal` model.

Until we have a proper editing UI in Dryad, journal metadata is still
edited with the UI in the v1 system, and then updates are imported
to the production server using a command like:
`RAILS_ENV=production bundle exec rails dryad_migration:migrate_journal_metadata`



Journal metadata is still available through the v1 journal module's API,
but **this feature is deprecated**.

List all journals:
`https://datadryad.org/api/v1/journals`

Get details about a single journal:
`https://datadryad.org/api/v1/journals/{issn}`

Get a list of datasets associated with a journal (up to 2019-09-17):
`https://datadryad.org/api/v1/journals/{issn}/packages`

Additional query parameters that can be used to modify the
results returned for the above calls:
- `count` specifies the number of results per page.
- `date_from` and `date_to` can filter results to packages released in a date range.
- `cursor` can be used to specify the key used to start the results page.

Processing journal emails
==========================

The email-processing functionality of the journal module is somewhat complex,
because it involves connection between several different services.

Send email for an existing journal
-----------------------------------

The workflow starts when a journal send an email to the
`journal-submit@datadryad.org` address. You can manually construct an
email and send it:

```
To: journal-submit@datadryad.org
Subject: Prepopulation data email

Journal Name: Journal of the American Medical Informatics Association
Journal Code: JAMIA
Online ISSN: 1067-5027
MS Reference Number: abc123-d
Article Status: submitted
MS Title: This is the title d
MS Authors: Someone, Joe; SomeoneElse, Tina
Abstract: I'm So Abstract
EndDryadContent
```

Processing the email
----------------------

The email is forwarded to the `journal-submit-app` account, which
automatically tags all new messages with `journal-submit`, and this
tag is removed when the production journal module processes each
message.

Development servers are normally configured to look for the tag
`dev-journal-submit`. If you need to have a message processed by a
development server, login to the email account and manually apply this tag.

To force a Dryad server to process the email, make a call like this:
`curl https://servername.datadryad.org/journal-submit/retrieve`

The results of email processing can be seen on the applicable server,
in the file `journal-submit.log`


Manscripts in the database
----------------------------

In the (v1) database, the processed manuscript metadata can be seen
with a command like:
`select msid, status, date_added from manuscript order by manuscript_id desc;`


Submitting a dataset using the manuscript metadata
---------------------------------------------------

1. On a Dryad server, using the normal UI, make a submission with the
   journal name and manuscript number.
2. Press the "Import Manuscript Metadata" button to retrieve the
   manuscript's metadata from the journal module. 
3. On the third submission page, select the option to put it into peer review
4. Submit the item, and wait for it to be processed into `peer_review`

Automatic updates of `peer_review` datasets
--------------------------------------------

When journals send updates of manuscript status, these updates trigger
changes in the status of associated datasets.

To see these changes:
1. Create a dataset in `peer_review` status as described above
2. Send an updated email, with the same manuscript number, but with `Article Status: accepted`
3. Process the email as described above
4. Verify that the associated manuscript has moved to `submitted` status


