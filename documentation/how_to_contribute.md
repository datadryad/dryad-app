# Introduction

The Dryad software provides a platform for depositing and managing data, working with descriptive metadata and additional services such as scholarly identifier registration or usage and citation tracking.

These guidelines are an attempt to ensure that we are able to provide a reliable system, stable APIs and clear communication.

**For the short version, take a look at
[this diagram of git flow](other_files/pull_request.pdf).**

## Pull Request (PR) methodology
We are using the "fork and pull model" for developing Dryad. [https://help.github.com/articles/about-collaborative-development-models/](https://help.github.com/articles/about-collaborative-development-models/) 

The basic flow of this model would be:

  - Be sure you have up-to-date code from the main repository and the main branch.
  - Create a new feature branch for your changes.
  This might be on a github repository forked from the main repo or it might be a new
  branch on the repo itself.
  - Develop your code and tests.
  - Keep your code up to date with accepted pull request changes that have been merged into the main
    branch daily (and before creating your final PR).
  - When code and tests are complete for your feature, do a pull request to merge
  the changes into the main branch for the repository and assign another core developer
  to review your changes.  (More about PR checklist below.)

## Testing

- Tests can be executed on a local machine by running `rails default` or `bundle exec rspec`
  inside either the main **dryad** repostiory
or inside an individual engine or gem directory in the **stash** repository.
- Individual tests in the dryad repository can be executed with `bundle exec rspec <path-to_test>`.
For example, `rspec spec/features/stash_datacite/manuscript_populate_metadata_spec.rb` .
  - Test names can be shown (instead of non-descriptive dots) with the -fd flag.
  - You can also tack a colon and a line number after the filename to only run
  a test starting on that line number.
- To run all tests inside the stash repository, type `RAILS_ENV=test bundle exec rspec`. 
- When making pull requests or pushes to a repository, GitHub will run tests, though they take 10 minutes
or so to run.

## Development flow

- Create a feature branch to develop changes.
- Develop changes and tests for your code \(see the pull request checklist below\).
- When the feature is complete
  - Move your github ticket from the **Current Iteration** column to the **Review** column in the dashboard.
  - Create your pull request for review and merging into the main branch


## End of sprint activities

- After we've had our end-of-sprint activities and review we generally make a tag of
all the stable code that has been accepted into main and approved by the
team and the product manager.
- In some cases, there may be very *minor* fixes requested before tagging.  We don't want
to hold up tagging too long for changes since we want to time-box our sprints.  It is also possible
to tag and then tag again as needed since tags are cheap.
- The deployment page has more specific instructions for tagging.
- We generally want to add release notes for a tag explaining the major features
on github, which is especially useful for public releases. Bullet points
are sufficient to explain main features and bug fixes.

## Pull request checklists

- **It has unit tests for added or changed methods** in *models* or *lib*.
These tests demonstrate that methods do as expected by themselves without added
complexity from other outside methods or services.
- We don't have tests for all controller methods, but have tested some critical
  ones and the API with requests tests (which test the controller and
  optionally returned http output)
- **It has *feature* tests for major UI functionality**.  No need for
tests for simple text changes in the UI
unless a text change breaks an existing test.  *Feature tests* load a page (or pages)
through an automated web browser using Capybara/Selenium and also can execute client-side
Javascript and other complex items.
- **It has *request* tests for API changes**.  Request tests are good for testing
a controller or for testing the request/response cycle for something that doesn't
need to execute any client-side Javascript code.
- **It links to any tickets if they're needed to understand the feature or function**.
- **It adds documentation or configuration changes** if either needs to be changed.
- **It supplies a little information about how to test, if it's not obvious**.  For
example, if you need a specific identifier or specific data to test, then please note
in the PR.
- **It adds major, brand-new layouts as examples in the UI library**.  Not required
for most things that are minor tweaks or have similar examples in the UI library.
- Other things?





  

