
Curation Workflow
==================

Dryad attempts to assist curators with their work while retaining as much
flexibility as possible.


Automatic assignment process
----------------------------

When a version of dataset a dataset is submitted, it is most efficient if it is
worked on by the same curator that worked on previous versions. Dryad will
attempt to automatically assign the previous curator.

If the previous curator is no longer with Dryad, a backup curator will be
assigned. This is the curator who has been with Dryad the longest, but who is
not a superuser, since superusers typically have many non-curation duties.


Automatic status changes
------------------------

Dryad attempts to set the status of a newly-submitted dataset based on its
history. The primary goal is that while a dataset is being actively curated, it
will be in "curation" status. A submitted version that the curator wasn't
expecting (e.g., author updates a dataset post-publication) results in
"submitted" status, so the curator can pick it up when they have time.

Major rules:
- If it has been in curation since the last published version, return it to curation
- If it has not been in curation since the last published version, leave it as submitted 

Workflow sequences and their resultant status:
- author submits, then updates themselves.... --> submitted
- author submits, curator edits --> curation 
- author submits, curator publishes, author resubmits --> submitted w/ curator assigned
- author submits, curator publishes, author resubmits, curator edits --> curation 
- author submits, curator returns aar, author edits --> curation 
- author submits, curator returns aar, author edits, curator edits --> curation 
