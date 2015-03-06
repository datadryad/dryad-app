------------------------------------------------------------
# Overall architecture

- How is this invoked -- batch, on-demand, both?
- Stateful? Stateless?

------------------------------------------------------------
# Harvesting

- How do we know what to harvest?
- What's OAI-PMH's concept of identity?

------------------------------------------------------------
# Ingesting

- What's Solr's concept of identity?

------------------------------------------------------------
# Configuration

- How should we configure the harvesting URL we pass to `OAI::Client::new`?
- What do we need to talk to Solr, and how should we configure it?
- What other parameters are there -- harvest frequency, etc.?

------------------------------------------------------------
# HTTP headers

- How do we set the `User-Agent` and `From` headers when making our HTTP requests?
- What should we set them to?

------------------------------------------------------------
# Testing

- Set up [Guard](https://github.com/guard/guard) to run tests automatically, since
  it's not like we can check for compilation errors
    - See [this StackOverflow answer](http://stackoverflow.com/questions/11996124/is-it-impossible-to-use-guard-with-rubymine/12000765#12000765)
      on using Guard with RubyMine / IntelliJ

------------------------------------------------------------
# Notes

- `ruby-oai` provides an `OAI::Provider` that could front a dummy repository for testing purposes

