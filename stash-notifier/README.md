# Stash

TLDR: The Stash Notifier reads OAI-PMH feeds from Merritt in order to
notify Dryad of successful ingests into Merritt. It also tracks *state*
of retrievals and submissions to Merritt and uses a *configuration* and
*environment variables* for configuring.

## The OAI-PMH Feed from Merritt

It reads an OAI-PMH feed from the Merritt storage repository.  That feed
has these commonly used parameters:

- Start time (from)
- End time (until)
- Set (Merritt collection to be returned)
- MetadataPrefix (The stash wrapper is returned)

## State

The script maintains state in the state/\<environment\>.json file which
tracks the last time for an OAI-PMH item so as not to duplicate retrieving
the whole feed every time, but just starting from where it left off.
The state also tracks items for retrying notifications to Dryad (if there
was a problem notifying it about the ingest state change).

The script will create the state file if it doesn't exist and retrieve
all items from the beginning of time if the state doesn't exist.  Redoing
all processing is a longer process than needed, but shouldn't create problems
since items in Dryad that have already had their Merritt state changed
will not have any additional actions taken.

## Configuration

The configuration does not contain sensitive information such as passwords,
so is committed as part of the repository. It is at config/notifier.yml.

- *update\_base\_url* -- the base URL to hit in order to notify Dryad.
- *oai\_base\_url* -- the base url for reading the OAI-PMH feed for this
environment.
- *sets* -- a YAML list of sets to harvest from the feed.  A set is
usually some variation of a Merritt collection name.

For run time configuration set these environment variables:

- STASH\_ENV is the application environment you'd like it work with from
the notifier.yml file.  It will default to *development* unless something
else is set otherwise.

- If *NOTIFIER\_OUTPUT* is set to a value of "stdout" then the script
will output logging to standard out rather than saving to the usual spot
with is logs/\<environment\>.log in the application directory.


## Running and a sample run

Execute "main.rb" which is a Ruby file.  You would want to do a "bundle install" if you have
not run it before.  Bundler will install all the required libraries (gems).

See this sample run.

```
$ STASH_ENV=localhost NOTIFIER_OUTPUT=stdout ./main.rb
I, [2019-01-28T15:44:08.432653 #24225]  INFO -- : Starting notifier run for localhost environment
/Users/sfisher/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/oai-0.4.0/lib/oai/client.rb:96: warning: constant ::Fixnum is deprecated
I, [2019-01-28T15:44:08.442428 #24225]  INFO -- : Checking OAI feed for cdl_dryaddev -- http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?from=2019-01-24T21%3A39%3A58Z&metadataPrefix=stash_wrapper&set=cdl_dryaddev&until=2019-01-28T23%3A44%3A08Z&verb=ListRecords
I, [2019-01-28T15:44:08.542798 #24225]  INFO -- : Notifying Dryad status, doi:10.5072/dryad.80gb5mn0, version: 2 ---- Testing the version number (2019-01-24T21:39:58Z)
I, [2019-01-28T15:44:08.723412 #24225]  INFO -- : Finished notifier run for localhost environment
```

## How should I deploy this?

Creating a special deployment script will likely take more time than it
will save and this items is unlikely to re-deployed very often.

1. git clone this repository.
2. Recursively copy the directory stash-notifier to the spot where you
want to run it.  (cp with the -r option.)
3. Change to the stash-notifier directory and do "bundle install" to be sure all gems
are installed.

Really it doesn't need a bunch of other stuff.  It's a simple Ruby (2.4.x)
script and as long as Ruby and the Gems it needs are installed, it should be happy.

## What about saving state?

Just save the state/\<environment\>.json fiie(s) to somewhere safe.  You
can copy them back in to a new deploy if you want.

Even if you lose them, you can just run the script and it will check all
items in the OAI-PMH feed.  If Dryad has already been notified that something
has finished in Merritt then it takes no action.