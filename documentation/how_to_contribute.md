# Introduction

The Dryad (formerly Dash) software provides a platform for depositing and managing data, working with descriptive metadata and additional services such as scholarly identifier registration or usage and citation tracking.

These guidelines are an attempt to ensure that we are able to provide a reliable system, stable APIs and clear communication.


## Pull request methodology
We are using the "fork and pull model" for developing Dryad. [https://help.github.com/articles/about-collaborative-development-models/](https://help.github.com/articles/about-collaborative-development-models/) 

The basic flow of this model would be to:

  - Fork repo to your account or somewhere else.
  - Clone your own copy of the repo to a machine to do work on.
  - add upstream for repo if needed and use it to get upstream changes in the future.

```
# for example
git remote add upstream https://github.com/CDLUC3/dashv2.git
git fetch upstream
git merge upstream/master
```
  
  - Make all needed changes and push them to your fork.
  - Create pull request from your fork to get them incorporated back into the main upstream repository.

(Please add feedback about this process since I may have missed details.)

# Testing
When creating pull requests travis.ci will run tests (TODO: which seem to break now and we need to fix), but you can generally run quick tests locally for just the areas you've changed and they'll run quickly if you don't want to wait around for Travis.ci or want to run them more iteratively to correct problems.

TODO: there are some areas where tests need to be added (mostly our initial version of an API), so we need to schedule work time for these tasks before long.

# Code review
- Tag another user to review your pull request.
- Changes at the model unit test level or UI level ("feature" level) should have rspec tests.  In some cases, you may need to use test doubles, aka "mocks" to simulate external services or items with complicated dependencies.

## Pull request checklists

Changes to database schemas or model classes

- Did you add or update any unit tests?
- Did you include any database migration?
- If you needed to transform data, did you include the changes in the migration (you may need to drop to raw SQL) or create a rake task?
- Did you also include the automatic updates to schema.rb when you committed?

Changes to views

- Did you add major UI changes such as new layouts, css styles or images to the [UI library](https://github.com/CDLUC3/stash/tree/master/stash_engine/ui-library) ?
- Are feature tests (browser automation) added or modified in order to test the change?




  

