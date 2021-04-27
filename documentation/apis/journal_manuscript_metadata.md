
Journal Manuscript Metadata
===========================

Introduction
------------

Journals may send metadata regarding their manuscripts to Dryad. These
notices allow Dryad to create and pre-populate a record for the data,
greatly facilitating the author's process of data deposit. These
messages also allow journals to communicate the status of manuscripts
to Dryad, allowing us to move the corresponding packages through our
curation process along with the journal's editorial process.

For journals wanting to create datasets directly, see the
[submission API](submission.md).


Required Metadata
-----------------

In order for Dryad to know how to uniquely associate a manuscript
with a data package, the manuscript metadata must include some minimal
information about the journal and the manuscript. These fields must
be included in every metadata email:

- *Journal Code:* journal-specific abbreviation that Dryad uses
  for internal management. This should have been specified during the
  journal's discussions with Dryad.
- *Journal Name:* full publication name of the journal.
- *MS Reference Number:* number that will be used to identify an
  article within Dryad during the submission process. This typically
  corresponds to the journal's internal manuscript number. If your
  submission system changes the manuscript number during the editorial
  process, please make sure that Dryad is aware of this.
- *MS Title:* title of the manuscript.
- *MS Authors:* authors, which should be listed as completely as
  possible. Dryad can accommodate several formats for the author list,
  as long as there is a clear way to distinguish the author names. The
  most common formatting is to list each author name in the format
  "Last, First" (without quotes) and separate authors with semicolons.
- *Article Status:* indicates whether the manuscript has been accepted
  as an article to publish. See values below. 


Article Status
--------------

An article can have one of several statuses; these statuses trigger
different components of the Dryad workflow.

- *submitted:* The manuscript has been submitted by an author, and is
being processed/reviewed by the journal. The author may elect to make
the data "private for peer review", or to make the data available
immediately after curation.
- *accepted*: The manuscript has been accepted for publication. Data
submitted to Dryad will be made available after curation, unless the
journal has selected Dryad's "blackout" period. If data had been
submitted previously, while the manuscript was under review, this data
will now become publicly available (again subject to any "blackout" period).
- *rejected:* The journal has rejected the manuscript or referred it
  to another journal. If data had been submitted while the manuscript
  was under review, the data will be moved back to the user's control,
  where it may be resumitted, possibly associated with a different
  journal.


Recommended Metadata
--------------------

- *Publication DOI:* if the article DOI is known, it is useful to include
this so that Dryad will be able find the published article and link
to it more easily. Please format with the prefix "doi:" (without the
quotes).


Optional Metadata
-----------------

Additional metadata may be included along with the
required/recommended metadata. Dryad parses all fields up to the
delimiter EndDryadContent.

Common fields:
- Print ISSN
- Online ISSN
- Journal Admin Email
- Journal Editor
- Journal Editor Email
- Contact Author
- Contact Author Email
- Keywords: Can be included as a comma- or semicolon-delimited list.
- Abstract: If the abstract is included in the email, it must be the last field
  in the email block, followed by EndDryadContent.
- Dryad Data DOI: This field is typically used by journals who have
  authors deposit data in Dryad prior to manuscript submission.

If your journal plans to include other fields, please contact Dryad
to make sure that our system will process them correctly.


Timing of notices
-----------------

It is best to send notices as soon as possible. That is:
- When an author completes submission of their manuscript,
  send a message with `Article Status: submitted`
- When a final decision is made on a manuscript,
  send a message with `Article Status: accepted` or `Article Status: rejected`


Metadata Submission via Email
-----------------------------

Dryad currently accepts manuscript metadata via email. Email is simple
and human-readable. It is also the easiest communication method for
many journals, since their manuscript processing systems already send
many templated email messages.

Dryad metadata can be parsed from a plaintext email as long as it
occurs in a single block in the email, starting with the Journal Code
and ending with EndDryadContent (or the end of the email itself).

Notices to the Dryad system can be generated as Dryad-specific messages from a
manuscript submission system. Alternatively, the metadata may be combined into
existing routine notices to authors. Some journals add the Dryad notice to their
standard emails to authors, prefacing the Dryad content with a statement like:
"Below is the information about your manuscript that we are relaying to the
Dryad repository to facilitate your data archiving."

Example email:

```
From: XXX
To: journal-submit@datadryad.org
Subject: Prepopulation data email
Sample message body
Note that the sample codes enclosed in hashes are the codes used by
ScholarONE. For other manuscript processing systems, different codes
will be required, but the basic format of the message should be the
same.

Journal Name: ##JOURNAL_NAME##
Journal Code: XXXX
Print ISSN: XXX
Online ISSN: XXX
Journal Admin Email: ##EMAIL_CONTACT_ADMIN_CENTER_EMAIL##
Journal Editor: ##PROLE_MANAGING_EDITOR_FIRSTNAME##
##PROLE_MANAGING_EDITOR_LASTNAME##
Journal Editor Email: ##PROLE_MANAGING_EDITOR_EMAIL##
MS Reference Number: ##DOCUMENT_ID##
Article Status: accepted
MS Title: ##DOCUMENT_TITLE##
MS Authors: ##DOCUMENT_AUTHORS##
Contact Author: ##PROLE_AUTHOR_FIRSTNAME## ##PROLE_AUTHOR_LASTNAME##
Contact Author Email: ##PROLE_AUTHOR_EMAIL##
Keywords: ##ATTR_KEYWORDS##
Abstract: ##DOCUMENT_ABSTRACT##
EndDryadContent
```

NOTE: the email block must end with EndDryadContent. If the Abstract
is present, it must be the last field in the block.

