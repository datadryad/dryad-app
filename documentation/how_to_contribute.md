This is a very sketch draft version that needs more discussion.


# Introduction

The Dryad (formerly Dash) software provides a platform for depositing and managing data, working with descriptive metadata and additional services such as scholarly identifier registration or usage and citation tracking.

These guidelines are an attempt to ensure that we are able to provide a reliable system, stable APIs and clear communication.


## Pull request methodology
Do we want to use the fork and pull model or the shared repository model?  [https://help.github.com/articles/about-collaborative-development-models/](https://help.github.com/articles/about-collaborative-development-models/)  Fork and pull: fork the code, make changes, push, pull request, merge.  Shared repo: create topic branch, pull requests do review and general discussion before merging into the main development.

If we're using the fork and pull then:

  - Fork repo to your account or somewhere else.
  - Clone your own copy of the repo to work on.
  - add upstream for repo if needed and use it to get upstream changes in the future.

```
# for example
git remote add upstream https://github.com/CDLUC3/dashv2.git
git fetch upstream
git merge upstream/development
```
  
  - Make all needed changes and push them to your fork.
  - Create pull request from your fork.

Does this seem right or are there other things I missed or don't understand about this process?

# Testing
When creating pull requests travis.ci will run tests (which seem to break with pull requests), but you can generally run quick tests locally for just the areas you've changed and they'll run quickly if you don't want to wait around for Travis.ci or want to run them more iteratively to correct problems.

Note: there are some areas where tests need to be added (mostly our initial version of an API), so we need time to do this if possible.

# Code review
Tag another user to review your pull request?

How are additional requested changes handled with pull requests?

## Pull request checklists

Changes to database schemas or model classes

- Did you add or update any unit tests?
- Did you include any database migration?
- If you needed to transform data, include the changes in either something in the migration or a rake task.
- schema.rb should also have changes and be committed.

Changes to views

- Major UI changes, add new layouts, css styles or images to the UI library
- Are feature tests (browser automation) added or modified to test the change?




  

