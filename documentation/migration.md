
# Migrating content from a DSpace-based Dryad system to a DASH-based Dryad system

## Data Migration

On the DASH system:

1. Ensure you have created an API account for the DSpace system to use, as described in [Adding a New API Account for Submission](https://confluence.ucop.edu/pages/viewpage.action?spaceKey=Stash&title=Dryad+Operations#DryadOperations-AddingaNewAPIAccountforSubmission).

On the DSpace system:

1. Ensure your maven settings file has appropriate values for the variables:
    - `default.dash.server` = protocol and hostname of the target server (e.g. http://ryandash.datadryad.org)
    - `default.dash.application.id` = oauth application ID
    - `default.dash.application.secret` = oauth application secret
    - `default.dash.submissions.finalize` = If true, the submission
      will be submitted for processing by Merritt. If false, all
      transfer will be done *except* the submission to Merritt (i.e.,
      the submission will remain "in progress" in the user's
      workspace). This is useful for dev servers that don't have access
      to Merritt.  
    - `default.dash.submissions.delaySeconds` = number of seconds to
    delay after each data package is submitted, to not overwhelm the
    dash server (a good default is 10) 
2. Find the handle or DOI of an item you want to transfer
3. To post a new item to Dash, call the curation tool from the command
   line, using the handle, such as: `/opt/dryad/bin/dspace curate -v -t transfertodash -i 10255/dryad.135814 -r -`
4. To view an item from Dash, call the dash-service tool from the
   command line, using the DOI, such as: `/opt/dryad/bin/dspace dash-service doi:10.5072/fzpe-zz40`

You may login to the Dash server and view the item.

### Implementation details

The DSpace implementation lives in these Java files:

- DryadDataPackage, DryadDataFile, DryadBitstream, Author, and Package = serialization of a Dryad package into Dash-formatted JSON
- DashService = API communications with Dash
- TransferToDash = curation task that manages bulk transfer of packages to Dash

The DASH implementation lives primarily in the [DASH submission API](https://github.com/CDL-Dryad/dryad/blob/master/documentation/api_submission.md).

## Statistics Migration

On the DSpace system:

1. Process the statistics into a log file:
   `/opt/dryad/bin/dspace curate -v -t dashstats -i 10255/3 -r - >dashStats.log`
2. Separate the log file into monthly files:
   `~/dryad-utils/dash-migration/sort_dash_stats.sh`
3. Any "nonstandard" lines from the dashStats.log will be collected in a file called "counter_". This file can be deleted.
4. Ensure the counter-processor is installed and configured as described at https://github.com/CDLUC3/counter-processor
5. Process the monthly files with the counter-processor:
   `python3 main.py`
   
   
