
Dates in Dryad
================

Dryad uses many dates in reports and internal calculations. These dates are
defined below. They are expressed here with CamelCase, but they may be expressed
in the system with CamelCase or snake_case, depending on the situation.

- CreatedDate -- The dataset was first created. Typically, when a user pressed the
  "New Dataset" button, or the dataset was first created via API.
- SubmittedDate -- The dataset was first submitted to the system. Typically, a
  user pressed the "Submit" button at the end of the submission process, and the
  dataset entered either `submitted` or `peer_review` status.
- PeerReviewDate -- This dataset first entered `peer_review`. If the dataset
  never entered `peer_review`, this date will be blank. 
- CurationStartDate -- The dataset first went either to `submitted` or
  `curation` status.
- CurationCompletedDate --  The status changed from `curation` to
  `action_required`, `embargoed` or `published`. 
- ApprovalDate -- The dataset was approved for publication. It entered the
  status `published` or `embargoed`.


The dates listed above are *per dataset*. Each of these dates may have a parallel
date for each version of the dataset.
