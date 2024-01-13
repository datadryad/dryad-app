# Stash::Merritt

## Submission process

The `Stash::Merritt::SubmissionJob` class does the following:

1. if no identifier is present, mint a new DOI with EZID
   (using the [ezid-client](https://github.com/duke-libraries/ezid-client) gem)
   and assign it to the resource
1. generate a ZIP package containing:

   | filename | purpose |
   | -------- | ------- |
   | `stash-wrapper.xml` | [Stash wrapper](https://github.com/CDL-Dryad/stash-wrapper), including [Datacite 4](https://schema.datacite.org/meta/kernel-4.0/) XML |
   | `mrt-datacite.xml` | [Datacite 3](https://schema.datacite.org/meta/kernel-3/) XML, for Merritt internal use. |
   | `mrt-oaidc.xml` | Dublin Core metadata, packaged in [oai_dc](https://www.openarchives.org/OAI/openarchivesprotocol.html#dublincore) format for [OAI-PMH](https://www.openarchives.org/OAI/openarchivesprotocol.html) compliance |
   | `mrt-dataone-manifest.txt` | legacy [DataONE manifest](http://cdluc3.github.io/dash/release-criteria/)* |
   | `mrt-delete.txt` | list of files to be deleted in this version, if any |

   \* Note that the DataONE manifest is generated for all tenants, not just DataONE.

1. Submit the package to Merritt through an api endpoint.
   A separate process updates the `download_uri` and `update_uri` of the resource to appropriate values after successful
   submission with the merritt_status:update rake task (which runs a daemon started by systemd).
1. set the resource `version_zipfile`
1. again via [ezid-client](https://github.com/duke-libraries/ezid-client), update the
   target URL (landing page) and Datacite 3 metadata for the DOI
1. clean up uploads and other temporary files
1. returns a successful `SubmissionResult`

If at any point one of these steps fails, the job exits with a failed `SubmissionResult`.

