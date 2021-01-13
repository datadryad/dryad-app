
Editorial Manager Bridging API
===============================

Dryad has a "bridging API" that translates between the needs of
Editorial Manager and the normal (submission API)[submission.md].

The bridging API takes requests in the Editorial Manager format,
transforms them into the format used by the Dryad API, runs the
regular process, and reformats the results into the output format
desired by Editorial Manager.

A single endpoint (`em_submission_metadata`) is used. It handles both
creating a new dataset (POST) or modifying an existing dataset (PUT).
The endpoint is also agnostic about whether the request is
the minimal "deposit" request or the more fully-specified "submission
metadata" request.

To use: make a submission request with the bridging endpoint, like
`curl --data "@my_metadata.json" -i -X POST https://<domain-name>/api/v2/em_submission_metadata -H "Authorization: Bearer <token>" -H "Content-Type: application/json"`

The JSON document that is submitted must have the format of either of Editorial Manager's
submission formats:
- (emDeposit.json)[emDeposit.json]
- (emSubmission.json)[emSubmission.json]

If an update is being provided for a previously-created dataset, the
encoded identifier for the dataset should be provided as a suffix to
the submission URL, like this:
`https://<domain-name>/api/v2/em_submission_metadata/<encoded_doi>`
