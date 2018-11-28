
# Migrating content from a DSpace-based Dryad system to a DASH-based Dryad system

On the DSpace system:

1. Ensure your maven settings file has appropriate values for the variables:
    - `default.dash.server` = protocol and hostname of the target server (e.g. http://ryandash.datadryad.org)
    - `default.dash.application.id` = oauth application ID
    - `default.dash.application.secret` = oauth application secret
    - `default.dash.submissions.finalize` = If true, the submission will be submitted for processing by Merritt. If false, all transfer will be done *except* the submission to Merritt (i.e., the submission will remain "in progress" in the user's workspace). This is useful for dev servers that don't have access to Merritt.
    -  `default.dash.submissions.delaySeconds` = number of seconds to delay after each data package is submitted, to not overwhelm the dash server (a good default is 10)
2. Find the handle or DOI of an item you want to transfer
3. To post a new item to Dash, call the curation tool from the command line, using the handle:
`/opt/dryad/bin/dspace curate -v -t transfertodash -i 10255/dryad.135814 -r -`
4. To view an item from Dash, call the dash-service tool from the command line, using the DOI: 
`/opt/dryad/bin/dspace dash-service doi:10.5072/fzpe-zz40`

You may login to the Dash server and view the item.
