
Journal information in Dryad
=============================

Dryad manages two types of information about journals:
1. Metadata about the journals and their workflows, which is used to manage
   processing of datasets associated with each journal.
2. Metadata about journal manuscripts, which can be imported into a dataset, and
   which can automatically change the status of a `peer_review` dataset.

Metadata about journals
=======================

Metadata about the journals and their workflows is stored in the following
models:
- `StashEngine::Journal`
- `StashEngine::JournalRoles`
- `StashEngine::JournalOrganizations`

Meaning of fields
-----------------

Options for processing in `StashEngine::Journal`

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
- *default_to_ppr* -- Whether the Peer Review checkbox should be checked by
  default when a new dataset is associated with this journal.

Adding journal administrators
-------------------------------

A user can be set as a journal administrator in two ways:
- Database: `insert into stash_engine_journal_roles (journal_id, user_id, role) values (1, 3, 'admin');`
- Rails console: `StashEngine::JournalRole.create(user: u, journal: j, role: 'admin')`

A user can also be set as an organizational administrator. The organization may
be a publisher, society, or other organization that sponsors the data
publication fees for a journal. To add a user as an organizational
administrator:
1. Ensure that the `JournalOrganization` exists
2. Ensure that all appropriate journals have the `JournalOrganization` listed as
   their `sponsor`
3. Ensure that the administrator has a `User` account
3. Add a `JournalRole` as in `StashEngine::JournalRole.create(user: u, journal_organization: o, role: 'org_admin')`

Alternate titles
================

Each journal has a primary title, but may have multiple `alternate_titles`.

To add an alternate title to a journal:
```
# Find the target journal and assign it to j

# Then create the alternate title
StashEngine::JournalTitle.create(title: 'Some new title', journal: j, show_in_autocomplete: true)
```

The `show_in_autocomplete` can be adjusted to false when adding a misspelling or
other journal name that should not be listed for public selection.


Cleaning journal names
=======================

When a journal name is not recognized by the system, the title is stored with an
asterisk appended. Periodically, new journals should be added to the system, and
old datasets should be updated to link them to the new journals.

Process all journal titles in the system, converting any with an asterisk to
the corresponding journal that has the same name:
`rails journals:clean_titles_with_asterisks`

Search for journals that are candidates to fix, in the database:
```
SELECT value, COUNT(value)
FROM stash_engine_internal_data
WHERE value like '%*%'
GROUP BY value
ORDER BY COUNT(value);
```

You can delete titles that are obviously junk or placeholders (e.g., "to be determined").

For each title, determine whether there is a corresponding journal in our
database.

IF there is no corresponding journal, create an entry for a new journal in the
system, using a command like the the one below. Edit any
of the relevant fields, but the most critical are `title` and `issn`.
```
j = StashEngine::Journal.create(title: '', issn: '',
                                notify_contacts: ["automated-messages@datadryad.org"], allow_review_workflow: true,
								allow_embargo: false, allow_blackout: false, sponsor_id: nil)
```

IF a new journal does not need to be created, add the new title as an
alternate_title to the journal.
```
StashEngine::JournalTitle.create(title: 'Some new title', journal: j, show_in_autocomplete: false)
```

Finally, replace the title throughout the system:
```
old_name = 'The Greatest Journal*'
new_id = 123
StashEngine::Journal.replace_uncontrolled_journal(old_name: old_name, new_id: new_id)
```

Updating journals for payment plans and integrations
====================================================

When a journal changes payment plans, simply update the `payment_plan_type`
field.

When a journal integrates with the email process, the journal must have the
`manuscript_number_regex` to properly process the email messages. The 
`issn` must also be set to select the proper email messages.

When a journal starts using API access, the associated API account must be
designated as an administrator of the journal. To enable a set of journals for
an API user, use something like:
```
u = StashEngine::User.find(<user_id>)
jj = StashEngine::Journal.where("title like '<title>%'") # or search by sponsor_id
jj.each do |j|
  StashEngine::JournalRole.new(user:u, journal:j, role:'admin').save
end
```


Metadata about Manuscripts
=============================

Metadata about manuscripts is stored in Dryad's
`StashEngine::Manuscript` model.

Submitting a dataset using the manuscript metadata
---------------------------------------------------

1. On a Dryad server, using the normal UI, make a submission with the
   journal name and manuscript number.
2. Press the "Import Manuscript Metadata" button to retrieve the
   manuscript's metadata from the journal module. 
3. On the third submission page, select the option to put it into peer review
4. Submit the item, and wait for it to be processed into `peer_review`


Processing journal emails
-------------------------

Journals send metadata emails to Dryad, which are parsed and stored in
preparation for the user to create an associated dataset. For details
on the format of these emails, see [journal_metadata.md](journal_metadata.md).


Overview of the email workflow
------------------------------

1. Journal sends email with article metadata to the
   `journal-submit@datadryad.org` email address, which forwards to `journal-submit-app@datadryad.org`
2. Messages in `journal-submit-app@datadryad.org` are automatically labeled
   by GMail with a special label.
3. At a regular interval, Dryad retrieves emails with the label, and processes
   them into `StashEngine::Manuscript` objects.
4. Later, a submitter may use the Submission System to retrieve the
   parsed metadata and initiate a new data submission.
5. If an email fails to parse properly because it's malformed, it will
   be tagged with a GMail error label.

Users with access to the `journal-submit-app` gmail account can also
manually add and remove the gmail labels to re-process specific
emails.


Testing the metadata emails
----------------------------

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
`rails journal_email:process`


Automatic updates of `peer_review` datasets
--------------------------------------------

When journals send updates of manuscript status, these updates trigger
changes in the status of associated datasets.

To see these changes:
1. Create a dataset associated with a journal as described above, and put it in `peer_review` status
2. Send an updated email, with the same manuscript number, but with `Article Status: accepted`
3. Process the email as described above
4. Verify that the associated dataset has moved to `submitted` status

When the email contains `Article Status: rejected`, the associated dataset will
be moved to `withdrawn` status.


Details of email processing
===========================

Configuring/updating the Rails connection with GMail
-----------------------------------------------------

Several settings need to be in the server's settings to connect with GMail.

Rails reads the GMail credentials from the credentials file, but it also needs a token that
will allow it to read from a specific GMail account. The token is stored in a
file called `google_token.json`, one directory above the codebase, so it is not
affected by updates to the codebase. You can test whether the
token is valid and/or reset the token by running:
`rails journal_email:validate_gmail_connection`

If something is wrong with the authorization, you can delete the `token.yaml`
file and generate it again. To generate it, login to Dryad as a superuser and navigate to
`/stash/gmail_auth`. Follow the instructions there.

Rarely, if the validation process above produces an error, you may need to regenerate
the application-level GMail credentials:
- must be logged in to GMail as journal-submit-app@datadryad.org
- go to https://console.cloud.google.com/apis/credentials
- select project "Dryad v2 Gmail API" (if needed)
- see the download icon for the entry "Rails OAuth"
- copy the client_id and client_secret out of the downloaded file and put them
  into the Rails credentials file

Configuring the Gmail labels
----------------------------

The labels that are being looked for by the webapp need to be configured in the
Gmail settings. Log into the Gmail web site as the
`journal-submit-app@datadryad.org` account. Create matching labels for the
server you're configuring, matching the
`APP_CONFIG[:google][:journal_processing_label]` and
`APP_CONFIG[:google][:journal_error_label]` settings. If you want to process
all incoming emails, set a filter that will label all incoming messages. Dryad
will remove that label as it processes the labeled emails. Note that if two
servers use the same label, they will both be proccesing the same set of
messages, and each message will only be processed by one server.


Full testing workflow
---------------------

Some of this information appears above, but the complete details are
provided here...

Set up the server:
- ensure all of the settings are correct in the `google` section of the
`app_config.yml`
- ensure the associated labels exist in the GMail account
- run `rails journal_email:validate_gmail_connection` to ensure the server can
  communicate with the GMail account

To run a test:
- Send an email to the Gmail account with the required metadata. The
  account can be journal-submit-app OR the more general
  journal-submit@datadryad.org. Note that you must use a "real" journal
  ISSNname to match the settings in the concept above. Something like:

```
Journal Name: Molecular Ecology
Journal Code: molecol
MS Reference Number: abc123
Article Status: submitted
MS Title: Some great and unique title
MS Authors: Author Authorious
Keywords: great research, stellar data
```

- In the GMail account (`journal-submit-app@datadryad.org`), apply the
  proper label to the email
- Force the email to be processed with `rails journal_email:process`
- Inspect the `StashEngine::Manuscript` table to ensure the email was processed
  correctly.
- Create a submission with the associated journal name and manuscript number. It
  should correctly import the metadata and use the journal settings to determine
  whether peer review is allowed and whether to charge the user. Normally, you
  will want to put the submission into `peer_review` status to test the
  subsequent steps.
- Wait for Merritt processing of the Dryad submission, or
  force the notifier to run (`notifier_force.sh` on most servers)
- Send another email to `journal-submit@datadryad.org` to update the
  status of the submission. This can be exactly the same message as
  above, just with the Article Status changed to either "accepted" or
  "rejected".
- Again, apply the correct label to the email.
- Again, force the email to be processed.
- View the results in server logs and the status of the submitted dataset.


Sample Rails commands
-----------------------

To initialize the GMail connection:
`rails journal_email:validate_gmail_connection`

To process emails:
`rails journal_email:process`

To use individual emails:
```
require 'stash/google/journal_gmail'
m=Stash::Google::JournalGMail.messages_to_process.first
mc=Stash::Google::JournalGMail.message_content(message: m)
ms=Stash::Google::JournalGMail.message_subject(message: m)
l=Stash::Google::JournalGMail.message_labels(message: m)
```

To access parsed metadata:
```
m=StashEngine::Manuscript.last
m.status
m.journal
m.manuscript_number
m.metadata['ms title']
m.metadata['ms authors']
```
