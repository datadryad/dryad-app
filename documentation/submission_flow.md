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
5. Harvesting
    * When Merritt has successfully ingested the dataset, it shows up in the OAI-PMH feed it exposes.
    * Harvester runs every 5 minutes and checks for updates.
    * With new updates it adds metadata into SOLR
    * Notifies UI that update has finished.
6. UI finishes actions for successfully submitted dataset when notified
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

stash/stash_engine/app/controllers/stash_engine/landing_controller.rb
- See the update method. This gets called back by the notifier service
  which is reading an OAI-PMH feed from Merritt which lists things that
  have gone in successfully.  
- This sets the merritt-status (stash_engine_resource_states) to 'submitted'.
- It will not set the completed, 'submitted' state more than once, so
  calling additional times will not have an effect (it returns early if
  it has already been updated). 
- updates size based on querying Merritt to get size after it was compressed/ingested.
- populates SWORD-type URLs if they're missing for some reason.
- cleans up temp files now that Merritt has told us ingest was successful.

Curation Status
=====================

Curation status is stored in resource.current_curation_activity (StashEngine::CurationActivity).

Allowable values:
- in_progress = the submitter is still working on the resource
- submitted = the submitter has submitted the resource for curation, but a curator has not picked it up yet
- peer_review = the resource is availble for reviewers to view, but curators will ignore it
- curation = a curator is working on the resource
- action_required = a curator has returned the resource to submitter for revision
- withdrawn = a previously-published resource has been removed from public view
- embargoed = metadata for the resource is published, but data files are not publicly available
- published = the resource is fully available to the public

