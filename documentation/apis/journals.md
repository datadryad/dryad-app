
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

Metadata about journals
=======================

Metadata about the journals and their workflows is stored in Dryad's
`StashEngine::Journal` model.

Meaning of fields
-----------------

Some of the fields in `StashEngine::Journal` are being updated as we
transition journals from older workflows to newer ones.

- *allow_review_workflow* -- Was previously used to determine whether
  a journal allowed authors to submit data during the manuscript
  review process. Controls whether the "private for peer review"
  checkbox is displayed in the submission system. All journals now
  have this set to `true`. 
- *allow_embargo* -- Was previously used to determine whether
  submitters saw a choice for embargoing their data after the article
  was published. Now has no effect, since we only allow user-requested
  embargoes in extraordinary circumstances.
- *allow_blackout* -- Was previously used to determine whether to
  "hide" a dataset until the associated article was published. Now
  controls whether an automatic 1-year blackout/embargo is added to
  the dataset.


Legacy data in v1 server
------------------------

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


Submitting a dataset using the manuscript metadata
==================================================

1. On a Dryad server, using the normal UI, make a submission with the
   journal name and manuscript number.
2. Press the "Import Manuscript Metadata" button to retrieve the
   manuscript's metadata from the journal module. 
3. On the third submission page, select the option to put it into peer review
4. Submit the item, and wait for it to be processed into `peer_review`


Processing journal emails
==========================

Journals send metadata emails to Dryad, which are parsed and stored in
preparation for the user to create an associated dataset. For details
on the format of these emails, see [journal_metadata.md](journal_metadata.md).


Overview of the email workflow
------------------------------

1. Journal sends email with article metadata to the
   `journal-submit@datadryad.org` email address, which forwards to `journal-submit-app@datadryad.org`
2. Messages in `journal-submit-app@datadryad.org` are automatically labeled
   by GMail with a special label.
3. At a regular interval, the journal-submit webapp retrieves the newest
   emails with the special label, saving those messages to process
   further and removing the label. The specific label is set by the maven
   settings on the server, so each Dryad server can react to a different
   label.
4. The webapp processes the new emails: it gets the byte stream with the
   email content and detects the journal's name.
5. The webapp then looks up the journal name in the journal concepts, to
   learn the `parsingScheme` to use. The value of this attribute is used
   to match on the parsing classes in the journal-submit's codebase.
6. When a particular parser is determined to be the correct one to use,
   the webapp uses that to parse the remainder of the email, putting
   metadata values into a ParsingResult object.
7. The ParsingResult class is then used to export the metadata into the
   database.
8. Later, a submitter will use the Submission System to retrieve the
   parsed metadata and initiate a new data submission.
9. If an email fails to parse properly because it's malformed, it will
   be tagged with the server's GMail error label.

Users with access to the `journal-submit-app` gmail account can also
manually add and remove the gmail labels to re-process specific
emails. To trigger the journal-submit webapp manually, use the a url like
https://whatever.server/journal-submit/retrieve.


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


Automatic updates of `peer_review` datasets
--------------------------------------------

When journals send updates of manuscript status, these updates trigger
changes in the status of associated datasets.

To see these changes:
1. Create a dataset in `peer_review` status as described above
2. Send an updated email, with the same manuscript number, but with `Article Status: accepted`
3. Process the email as described above
4. Verify that the associated manuscript has moved to `submitted` status


Technical details for the journal module
========================================

Configuring the journal-submit webapp
-------------------------------------

Several settings need to be in the server's Maven settings.xml
file. The following are example settings for the main production
server. Please choose unique settings for your own server's label and
error label, e.g. dev-journal-submit and dev-journal-submit-error for
the dev server.

The JSON data for the clientsecret can be found in the Maven settings
on dev or production, or can be obtained directly from Google via
https://console.developers.google.com/project/journal-submit/apiui/credential
and is the downloaded JSON for "Client ID for native application."

Troubleshooting
---------------

If running http://localhost:9999/journal-submit/test returns errors,
it is possible that the stored credential has gotten out of
sync. Delete the credential file on the server (stored at
/opt/dryad/submission/credential/StoredCredential) and reauthorize the
webapp.

If running http://localhost:9999/journal-submit/retrieve returns an
error saying that messages are still being processed, you can clear
that by running http://localhost:9999/journal-submit/clear.


Authorizing the webapp
----------------------

This should only need to be done when a server is deploying the webapp
for the very first time: the credentials should remain authorized
unless and until someone revokes the access through the Google
Developer Console.

Once configured, built, and running, start the Tomcat instance and
authorize the webapp for accessing the Gmail account:

Go to a web browser and navigate to
http://localhost:9999/journal-submit/authorize (or whatever address
the Tomcat server is running at) and follow the OAuth2 instructions.

When you are provided with an auth code, copy it and make a call to
http://localhost:9999/journal-submit/authorize?code=whateverthecodeis
to authorize the webapp.

Restart tomcat and run http://localhost:9999/journal-submit/test and
you should get a test message in your journal-submit.log file.


Configuring the Gmail labels
----------------------------

The labels that are being looked for by the webapp need to be
configured in the Gmail settings. Log into the Gmail web site as the
`journal-submit-app@datadryad.org` account. Create matching labels for
the server you're configuring, matching the
`<default.submit.journal.label>` and
`<default.submit.journal.error.label>` settings in the Maven settings
file (as above). If you want to listen for all incoming emails, set a
filter to label all incoming messages with the label. The webapp will
remove that label as it processes the labeled emails. Do not use an
existing label for a new server instance, or else the new server's
webapp will remove some other server's labels!


Full testing workflow
---------------------

Some of this information appears above, but the complete details are
provided here...

Set up the servers:
- On the target Dryad/Dash server,
  - Ensure it has the correct authentication for the Dryad/DSpace
    server. This is in app_config.yml, old_dryad_url and
    old_dryad_access_token
- On the Dryad/DSpace server (dryad-dspace-server) that will process
  emails,
  - Ensure it has a journal concept set up with the journal name and
    settings that you want to test.
  - Ensure it has authentication information for the correct email
    account. This account is usually journal-submit-app@datadryad.org for
    all servers, so shouldn't require a change. In dspace.cfg,
    submit.journal.clientsecrets
  - Check which email label it will look for. This is in dspace.cfg,
    submit.journal.email.label
  - Ensure it has the correct authentication for the Dryad/Dash
    server. This is in dspace.cfg, dash.server and associated auth key.

To run the test:
- Send an email to the Gmail account with the required metadata. The
  account can be journal-submit-app OR the more general
  journal-submit@datadryad.org. Note that you must use a "real" journal
  name to match the settings in the concept above. Something like:

```
Journal Name: Molecular Ecology
MS Reference Number: abc123
Article Status: submitted
MS Title: Some great and unique title
MS Authors: Author Authorious
Contact Author: Author Authorious
Contact Author Email: fake-author@datadryad.org
Keywords: great research, stellar data
```

- In the GMail account (journal-submit-app@datadryad.org), apply the
  proper label to the email
- Either wait, or force the email to be processed by accessing
  http://dryad-dspace-server.datadryad.org/journal-submit/retrieve
- View the logs on the Dryad/V1 server to ensure the email was processed
  correctly.
- On the Dryad/Dash server, create a submission with the associated
  journal name and manuscript number. It should correctly import the
  metadata and use the journal settings to determine whether peer review
  is allowed and whether to charge the user. Normally, you will want to
  put the submission into peer_review status to test the subsequent steps.
- Either wait for Merritt processing of the Dryad/Dash submission, or
  force the notifier to run (notifier_force.sh on most servers)
- Send another email to journal-submit@datadryad.org to update the
  status of the submission. This can be exactly the same message as
  above, just with the Article Status changed to either "accepted" or
  "rejected".
- Again, apply the correct label to the email.
- Again, wait or force the email to be processed.
- View the results in server logs and the status of the Dryad/Dash submission.
