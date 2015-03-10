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

## Questions

- Stateful? Stateless?

------------------------------------------------------------
# Notes

- `ruby-oai` provides an `OAI::Provider` that could front a dummy repository for testing purposes

