
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
- `StashEngine::JournalOrganizations`


Meaning of fields
-----------------

Options for processing in `StashEngine::Journal`:
- *allow_review_workflow* -- Was previously used to determine whether
  a journal allowed authors to submit data during the manuscript
  review process. Controls whether the "private for peer review"
  checkbox is displayed in the submission system. All journals now
  have this set to `true`.
- *default_to_ppr* -- Whether the Peer Review checkbox should be checked by
  default when a new dataset is associated with this journal.

There may also be a journal organization. The organization may
be a publisher, society, or other organization that sponsors the data
publication fees for a journal.

Organizational relationships:
- `StashEngine::Journal.sponsor` is the organization that controls the journal
  and causes it to be sponsored. Note that the actual payments may come from a
  parent organization of the sponsor.
- `StashEngine::JournalOrganization.parent` is a parent organization that provides funding
  for a lower-level organization.

The organizational relationships are used for:
- permissions (which journals an administrator controls; see below)
- display of sponsorship (who to credit throughout the Dryad site)
- actual sponsorship (who to bill)


Adding journal administrators
-------------------------------

1. Ensure that the `Journal` exists
2. Ensure that the `JournalOrganization` exists (if required)
3. Ensure that all appropriate journals have the `JournalOrganization` listed as
   their `sponsor`
4. Ensure that the administrator has a `User` account

A user can be set as a journal administrator or an organizational administrator
most easily through the user management UI.

A user can also be set as a journal administrator in the Rails console: 
```ruby
StashEngine::Role.create(user: <User>, role_object: <Journal or JournalOrganization>, role: 'admin')
```


Alternate titles
================

Each journal has a primary title, but may have multiple `alternate_titles`.

To add an alternate title to a journal:
```ruby
StashEngine::JournalTitle.create(title: 'Some new title', journal_id: <the journal id>, show_in_autocomplete: false)
```

The `show_in_autocomplete` can be adjusted to false when adding a misspelling or
other journal name that should not be listed for public selection.


Cleaning journals
=================

When a journal name is not recognized by the system, it is stored in the resource's `resource publication.publication_name` without an accompanying `publication_issn`. ISSNs may also be added to this table by curators, without an accompanying entry in the `journal_issns`. Periodically, new journals should be added to the system, and old datasets should be updated to link them to the new journals.

This is primarily used for related primary articles. Look at unmatched primary articles in the system, adding a publication_issn if one exists.

### Unmatched primary articles

```ruby
# primary articles with no matched journal, a relevant subset of all unmatched publications
StashEngine::Resource.latest_per_dataset.joins('join dcs_related_identifiers r on r.resource_id = stash_engine_resources.id and r.work_type = 6 and r.related_identifier is not null').joins(:resource_publication, :identifier).left_outer_joins(:journal).where(journal: {id: nil}).where.not(identifier: {pub_state: 'withdrawn'}).distinct.pluck('stash_engine_resources.id', 'stash_engine_identifiers.id', 'stash_engine_identifiers.identifier', 'r.related_identifier', 'stash_engine_resource_publications.publication_name', 'stash_engine_resource_publications.publication_issn')
```

You can sort by the entered publication (regardless of case and starting with 'the') to group them in order of title and see which are used more than once: `.sort_by {|s| [s[4]&.downcase&.gsub(/^the /, '') ? 1 : 0, s[4]&.downcase&.gsub(/^the /, '')]}`. This returns an array of arrays of the following format:

`[<resource ID>, <identifier ID>, <dryad DOI>, <primary article DOI>, <unmatched publication_name (or nil)>, <unmatched publication_issn (or nil)>]`

Visit a primary article DOI. Determine if it is from a journal already in our system, and add the journal information to the resource_publications table. You can also easily do this from the activity log UI for each dataset.

```ruby
j = StashEngine::Journal #get your journal
StashEngine::Resource.find(<id>).resource_publication.update(publication_name: j.title, publication_issn: j.single_issn)
```

If a journal ISSN is already listed as the publication_issn, and is correct for the journal, you should add the ISSN to the journal. You can also easily do this from the journal admin UI.
```ruby
StashEngine::JournalIssn.create(id: <issn>, journal: j)
```

If the journal name is present and is a reasonable variation for the journal, consider if it should be added as an alternate title:
```ruby
StashEngine::JournalTitle.create(title: 'Some new title', journal_id: <the journal id>, show_in_autocomplete: false)
```

**NOTE: ONLY add journals that have more than 1 deposit in Dryad.**

If there is no corresponding journal, you can create an entry for a new journal in the system. You must also create entries for each of the journal's ISSNs:
```ruby
j = StashEngine::Journal.create(title: <journal title>)
StashEngine::JournalIssn.create(id: <issn>, journal: j)
```

### Unmatched manuscripts

If all primary articles are processed, you can do a similar process for results where users have entered a publication_name and a manuscript_number but no ISSN was found.

```ruby
# manuscripts with no matched journal, a relevant subset of all unmatched publications
StashEngine::Resource.latest_per_dataset.joins(:resource_publication, :identifier).left_outer_joins(:journal).where(journal: {id: nil}).where.not(resource_publication: {manuscript_number: [nil, ''], publication_name: [nil, '']}).where.not(identifier: {pub_state: 'withdrawn'}).distinct.pluck('stash_engine_resources.id', 'stash_engine_identifiers.id', 'stash_engine_identifiers.identifier', 'resource_publication.manuscript_number', 'resource_publication.publication_name', 'resource_publication.publication_issn')
```

You can sort by the entered publication to group them in order of title and see which are used more than once: `.sort_by {|s| [s[4]&.downcase&.gsub(/^the /, '') ? 1 : 0, s[4]&.downcase&.gsub(/^the /, '')]}`. Or, group them by manuscript number, which can be in standard formats for our partner journals: `.sort_by {|s| [s[3]&.downcase ? 1 : 0, s[3]&.downcase]}`. This returns an array of arrays of the following format:

`[<resource ID>, <identifier ID>, <dryad DOI>, <manuscript number>, <unmatched publication_name>, <unmatched publication_issn (or nil)>]`

Ignore any results for which the manuscript number or publication name are gibberish, or otherwise wrong. If they seem real and relevant, you can check and add journals as above.

**NOTE: ONLY add journals that have more than 1 deposit in Dryad.**


Updating journals for payment plans and integrations
====================================================

When a journal changes payment plans, simply update the `payment_plan_type`
field. If the change needs to be retroactive, use this function in the Rails console,
and then re-generate any needed shopping cart reports:
```ruby
# Update the payment types for datasets associated with a journal in a given month
# usage: change_journal_payment_type(year_month: '2023-01',
#                                    journal_id: 220, 
#                                    new_payment_type: 'journal-DEFERRED')

def change_journal_payment_type(year_month:, journal_id:, new_payment_type:)
  limit_date = Date.parse("#{year_month}-01")
  limit_date_filter = "updated_at > '#{limit_date - 1.day}' AND created_at < '#{limit_date + 1.month}' "
  StashEngine::Identifier.publicly_viewable.where(limit_date_filter).each do |i|
    approval_date_str = i.approval_date&.strftime('%Y-%m-%d')
    if i.payment_type == 'stripe'
      puts "Skipping invoiced dataset #{i.identifer}"
      next
    end
    next unless approval_date_str&.start_with?(year_month)
    next unless i.journal&.id == journal_id
    puts "#{i.identifier} -- #{i.payment_type} --> #{new_payment_type}"
    i.update(payment_type: new_payment_type)
    i.update(payment_id: StashEngine::Journal.find(journal_id).single_issn)
  end
  nil
end
```

When a journal integrates with the email process, the journal must have the
`manuscript_number_regex` to properly process the email messages. The 
`issn` must also be set to select the proper email messages.

When a journal starts using API access, the associated API account must be
designated as an administrator of the journal. To enable a set of journals for
an API user, use something like:
```ruby
u = StashEngine::User.find(<user_id>)
jj = StashEngine::Journal.where("title like '<title>%'") # or search by sponsor_id
jj.each do |j|
  StashEngine::Role.new(user: u, role_object: j, role: 'admin').save
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
on the format of these emails, see [journal_manuscript_metadata.md](journal_manuscript_metadata.md).


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
file called `google_token.json`, outside the codebase, so it is not
affected by updates to the codebase. You can test whether the
token is valid and/or reset the token by running:
`rails journal_email:validate_gmail_connection`

If something is wrong with the authorization, you can delete the `google_token.json`
file and generate it again. To generate it, login to Dryad as a superuser and navigate to
`/gmail_auth`. Follow the instructions there.

If you get an error about "Credentials do not contain a refresh_token.", You
will need to de-authorize Dryad for this account (because it only sends the
refresh token on the first authorization). Go to
https://myaccount.google.com/u/0/permissions and remove the Dryad application.

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
  name to match the settings in the concept above. Something like:

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
- Wait for repository processing of the Dryad submission
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
```ruby
require 'stash/google/journal_g_mail'
m=Stash::Google::JournalGMail.messages_to_process.first
mc=Stash::Google::JournalGMail.message_content(message: m)
ms=Stash::Google::JournalGMail.message_subject(message: m)
l=Stash::Google::JournalGMail.message_labels(message: m)
```

To access parsed metadata:
```ruby
m=StashEngine::Manuscript.last
m.status
m.journal
m.manuscript_number
m.metadata['ms title']
m.metadata['ms authors']
```
