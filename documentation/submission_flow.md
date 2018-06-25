Dash Submission Flow

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
