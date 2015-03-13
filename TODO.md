------------------------------------------------------------
# Harvesting

- How do we know what to harvest?
    - dash2 sends us a record identifier
    - the `metadataPrefix` is configurable (?)
- What's OAI-PMH's concept of identity?
    - items have identifiers
    - identifiers are URIs
    - identifier URIs can have arbitrary schemes, but if it's a well-known scheme they must be sensible for that scheme
    - the OAI-PMH identifier **is not** the URI of the resource; that's what the Dublin Core `identifier` element *within* the metadata is for
- How do we test configuration?
    - checking OAI-PMH configuration:
        - repository URI is correct
        - `metadataPrefix` is a supported format
            - using the `ListMetadataFormats` verb; see e.g. [http://oai.datacite.org/oai?verb=ListMetadataFormats](http://oai.datacite.org/oai?verb=ListMetadataFormats)
    - checking Solr configuration: **???**

------------------------------------------------------------
# Solr

Solr setup:

- Where do we assume Solr lives / how do we assume Solr is deployed?
- Do we take Solr as a given, the way we take the repository as a given, or is it (conceptually) embedded our Blacklight app?
- Are we the only source of Solr data?

Solr configuration:

- Compare [DataCite's Solr config](https://github.com/datacite/search/tree/master/src/main/resources)

------------------------------------------------------------
# Ingesting

- What's Solr's concept of identity?

------------------------------------------------------------
# Configuration

- How should we configure the harvesting URL we pass to `OAI::Client::new`?
- What do we need to talk to Solr, and how should we configure it?
- What other parameters are there -- harvest frequency, etc.?

------------------------------------------------------------
# HTTP

- How do we set the `User-Agent` and `From` headers when making our HTTP requests?
- What should we set them to?
- Don't retry immediately if you get a 4xx or 5xx or whatever
    - but check for `Retry-After` headers
    - default to retry after some several minutes, and/or manual intervention is OK
    - if we're going to auto-retry, we should configure that
- Follow 302 Found redirects with Location header
    - don't retry (immediately?) 302 Founds without Location header

------------------------------------------------------------
# Good harvesting citizenship

Note: this doesn't really apply to record-by-record requests.

- Check repository time granularity
- Overlap datestamp-based harvests
- Understand and use `resumptionTokens`
    - including `badResumptionToken` errors
    - including possible `expirationDate` attributes


------------------------------------------------------------
# Testing

- Set up [Guard](https://github.com/guard/guard) to run tests automatically, since
  it's not like we can check for compilation errors
    - See [this StackOverflow answer](http://stackoverflow.com/questions/11996124/is-it-impossible-to-use-guard-with-rubymine/12000765#12000765)
      on using Guard with RubyMine / IntelliJ

- Sample data from `oai.datacite.org`:
    - [DataCite XML example](http://oai.datacite.org/oai?verb=GetRecord&identifier=oai:oai.datacite.org:32153&metadataPrefix=datacite)
    - [Dublin Core example](http://oai.datacite.org/oai?verb=GetRecord&identifier=oai:oai.datacite.org:32153&metadataPrefix=oai_dc)

------------------------------------------------------------
# Overall architecture

## Operations

1. read metadata from OAI-PMH
    - dash2 provides us an `identifier`
    - we send that `identifier` in a `GetRecord` request to the OAI-PMH repository
    - something like:
      <pre>
      client = OAI::Client.new 'http://localhost:3333/oai'
      response = client.get_record {:identifier => 'oai:test/3', :metadata_prefix => 'oai_dc'}
                                   # TODO is this syntax correct / Ruby-ish?
      </pre>

2. extract metadata from OAI repsonse
    - it comes back as an `REXML::Element`

3. write metadata to Solr

## Invocation

- How is this invoked -- batch, on-demand, both?
- Is the upload UI the only source of data & metadata, or are there other front ends?

## Synchronous or asynchronous?

- [ruby-oai](https://github.com/code4lib/ruby-oai) uses [Faraday](https://github.com/lostisland/faraday) which in theory should allow async I/O? But it appears to use it only in a synchronous manner? Hard to tell.
    - see [OAI::Client](https://github.com/code4lib/ruby-oai/blob/master/lib/oai/client.rb)
- [rsolr](https://github.com/code4lib/ruby-oai) uses straight [Net::HTTP](http://ruby-doc.org/stdlib-2.2.1/libdoc/net/http/rdoc/Net/HTTP.html) but it looks like it would be simple to hack/extend to use e.g. [em-http-request](https://github.com/igrigorik/em-http-request)
    - see [RSolr::Client](https://github.com/rsolr/rsolr/blob/master/lib/rsolr/client.rb)
    - ref: "[An introduction to eventmachine, and how to avoid callback spaghetti](http://rubylearning.com/blog/2010/10/01/an-introduction-to-eventmachine-and-how-to-avoid-callback-spaghetti/)"

## Questions

- Stateful? Stateless? (Please say stateless.)

------------------------------------------------------------
# Notes

- `ruby-oai` provides an `OAI::Provider` that could front a dummy repository for testing purposes

