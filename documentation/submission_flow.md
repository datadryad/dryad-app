Basic Dryad Submission Flow
=============================

1. Fill in metadata (DataCite)
    * Mostly AJAX in one page by way of JQuery and/or Rails Unobtrusive Javascript (UJS)
    * Other widgets in page include mapping (Leaflet), links out to ORCID login to validate user
2. Upload files
    * Upload files directly (get copied onto web server until successful submission)
    * Or choose URLs where files are located and can be retrieved by http(s).  They are validated that they exist and a download can start.
      * Also some transformations of Google Drive/Box/Dropbox URLs into the download links
3. Review before submit
    * Missing required data shown
    * Review display
    * Private for peer review (embargo) delay can be set
    * Accept license
4. Submission
    * Update metadata with EZID/DataCite for the submitted item.
    * Uses SWORD to submit to Merritt in background process
    * SWORD submission is currently synchronous within background process
    * Package sent contains manifest (for URLs) or zip file with metadata files and data files
      * Mrt-datacite.xml, mrt-dataone-manifest.txt, mrt-embargo.txt, mrt-oaidc.xml, stash-wrapper.xml sent to merritt
      * If sending a manifest, these xml files are hosted on the Dash server and picked up by Merritt as part of its ingest.
5. Notifying of completion
    * When Merritt has successfully ingested the dataset, the dataset
      shows up in Merritt's [local id search](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/CDLUC3/mrt-dashboard/main/swagger.yml#/experimental/get_api__group__local_id_search)
    * A daemon in a rake task runs to check for updates can be
      started like `RAILS_ENV=development rails merritt_status:update` or
      likely will be added to systemd startup scripts on one server.
    * With new updates it updates status for items that have gone through Merritt
6. UI finishes actions for successfully submitted dataset
    * Sets download_uri and update_uri if needed
    * Changes state to ‘submitted’
    * Cleans up staged, temporary files for this submission
    * Delivers invitations for co-authors without ORCIDs
    * Updates the total dataset size by querying Merritt


Merritt States
=================

The Merritt status is stored in resource.current_resource_state (StashEngine::ResourceState).
Allowable values:
- in_progress = someone is editing and hasn't submitted this version to Merritt yet
- processing = processing through Merritt as a submission right now (or maybe stalled in rare circumstances)
- submitted = submitted to Merritt successfully
- error = some error occurred while submitting to Merritt

Curation Status
=====================

Curation status is stored in resource.last_curation_activity (StashEngine::CurationActivity).

Allowable values:
- in_progress = the submitter is still working on the resource
- submitted = the submitter has submitted the resource for curation, but a curator has not picked it up yet
- peer_review = the resource is availble for reviewers to view, but curators will ignore it
- curation = a curator is working on the resource
- action_required = a curator has returned the resource to submitter for revision
- withdrawn = a resource has been removed from public view, either manually by
  the curator or automatically based on the journal's notification of a rejected article
- embargoed = metadata for the resource is published, but data files are not publicly available
- published = the resource is fully available to the public

