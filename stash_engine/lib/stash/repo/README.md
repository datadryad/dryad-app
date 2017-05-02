# Stash::Repo

This is the repository abstraction for Stash.

##### TO DO:

- separate identifier assignment from submission
- configure `SubmissionJob` subclass directly, so implementors don't have to 
  subclass `Repository`
- identify `Stash::Merritt`-specific database fields and move them to their own
  tables self-contained in that gem

## Workflow

1. Stash instantiates the configured subclass of `Stash::Repo::Repository`.
2. Stash calls `Repository#submit(resource_id:)` to submit a resource.
3. The configured `Repository` instance creates a `Stash::Repo::SubmissionJob`
   for the resource.
4. `Repository` submits the job in the background, using
   [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby)'s
   [global I/O executor](https://ruby-concurrency.github.io/concurrent-ruby/root/Concurrent.html#global_io_executor-class_method).
5. When the job completes
   - **successfully**: `Repository` sends a confirmation email to the resource author.
     - **ᴛᴏ ᴅᴏ:** should we put this off till after harvesting, below?
   - **unsuccessfully**: `Repository` sets the resource state to `error`
     and sends a notification to the resource author, as well as to
     the configured feedback email address.
6. Stash harvests the submitted resource from the repository, confirming that the
   repository has finished any post-submit processing
7. `Repository` sets the resource state to `submitted` and sets the download and 
    update URIs for the resource
    - **ᴛᴏ ᴅᴏ:** should we send the confirmation email (or another "processing 
      completed" email) at this point?
     
## Implementation responsibilities

### `Stash::Repo::Repository`

Your subclass of `Stash::Repo::Repository` should override:

#### `#create_submission_job(resource_id:)`

Returns an instance of `Stash::Repo::SubmissionJob` that will assign an identifier to
and submit the resource.

#### `#download_uri_for(resource_id:, record_identifier:)`

Determines the download URI for the resource, given the repository-specific harvested
record identifier (e.g. OAI-PMH record header identifier). Note that the primary identifier
(e.g. DOI) should already be in the database, and can be retrieved based on the resource ID.

#### `#update_uri_for(resource_id:, record_identifier:)`

Determines the update URI for the resource, given the repository-specific harvested
record identifier (e.g. OAI-PMH record header identifier). Note that the primary identifier
(e.g. DOI) should already be in the database, and can be retrieved based on the resource ID.

### `Stash::Repo::SubmissionJob`

Your subclass of `Stash::Repo::SubmissionJob` should override:

#### `#description`

Returns a description of the job. This may include the resource ID, the type
of submission (create vs. update), and any configuration information (repository 
URLs etc.) useful for debugging, but should not include any secret information 
such as repository credentials, as it will be logged.

#### `#submit!`

The `#submit!` method has (currently) two main responsibilities: 

1. Mints and assigns an identifier to the resource, if not already assigned
2. Submits the resource to the repository, returning a `SubmissionResult` to
   indicate success or failure

This method will be called from a background thread, and with its own ActiveRecord
connection. Any ActiveRecord models needed by the task should be created in this 
method, and should not be returned, yielded, thrown, or passed outside it.
