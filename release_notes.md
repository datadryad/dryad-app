# Release notes

## v0.1.15 to v0.1.21 (Nov 18 to Dec 9, 2016)

- UC Merced logo -- Added extra space added on top

- Maximum upload size is displayed based on configuration in all places

- Ajax loading errors fixed, caused by jquery-ui gem released with missing dependencies, updated to later version of gem

- Added manual script to import file list from an Atom feed when we must do manual deposit

- Renaming resource_type field to resource_type_general which is what this controlled list actually represents

- Adding resource_type_general (free text) and updating all code so it fills in both values and uses the new fields

- Up to 2 GB submissions

  - (In private puppet repo) Updating Apache config to allow longer http requests before the balancer times out

  - Updating Capistrano deploy to allow longer-running background tasks to complete before they are killed

  - Updated configuration to allow larger submissions

- Installed rspec testing framework and set up directories

- Minor cleanup of stash-sword gem and file upload code

- Use short campus names when possible -- both tenant display and autocompletion when available

- Fixing "Participating Partners" drop-down to stay on top of buttons/text on the page

- Simplify code that sets the version number for an identifier

- Fix DOI formatting/links in email