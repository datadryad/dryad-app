# stash-wrapper

[![Build Status](https://travis-ci.org/dmolesUC3/stash-wrapper.png?branch=master)](https://travis-ci.org/dmolesUC3/stash-wrapper)
[![Code Climate](https://codeclimate.com/github/dmolesUC3/stash-wrapper.png)](https://codeclimate.com/github/dmolesUC3/stash-wrapper)
[![Inline docs](http://inch-ci.org/github/dmolesUC3/stash-wrapper.png)](http://inch-ci.org/github/dmolesUC3/stash-wrapper)

Gem for working with the Stash [XML wrapper format](https://dash.cdlib.org/stash_wrapper/stash_wrapper.xsd).

The `StashWrapper` object graph mostly mirrors the `stash_wrapper` schema, though some
simpler elements have been collapsed into object attributes. Also, some classes and
attributes have slightly different names from the corresponding XML attributes in order
to avoid colliding with Ruby keywords (e.g. `end` &rArr; `end_date`) or standard types
(e.g. `file` &rArr; `StashFile`).

| Schema element | Corresponding class or field | Attribute type |
| -------------- | ------------------- | ---- |
| `<st:stash_wrapper>` | `StashWrapper` | |
| `<st:identifier>` | `Identifier` | |
| `<st:stash_administrative>` | `StashAdministrative` | |
| `<st:version>` | `Version` | |
| `<st:version_number>` | `Version.version_number` | `Integer` |
| `<st:date>` | `Version.date` | `Date` | |
| `<st:license>` | `License` | |
| `<st:name>` | `License.name` | `String` |
| `<st:uri>` | `License.uri` | `URI` |
| `<st:embargo>` | `Embargo` | |
| `<st:type>` | `Embargo.type` | `EmbargoType` |
| `<st:period>` | `Embargo.period` | `String` |
| `<st:start>` | `Embargo.start_date` | `Date` |
| `<st:end>` | `Embargo.end_date` | `Date` |
| `<st:inventory>` | `Inventory` | |
| `<st:file>` | `StashFile` | |
| `<st:pathname>` | `StashFile.pathname` | `String` |
| `<st:size>` | `Size` | |
| `<st:mime_type>` | `StashFile.mime_type` | `MIME::Type` |
| `<st:stash_descriptive>` | `StashWrapper.descriptive_elements` | `Array<REXML::Element>` |

Note that [Ruby::Enum](https://github.com/dblock/ruby-enum) enum classes are provided
for embargo type (`EmbargoType`), identifier type (`IdentifierType`), and size unit
(`SizeUnit`).

## Usage

The `Stash::Wrapper::StashWrapper` class represents a single Stash wrapper document.
It accepts a payload of one or more XML metadata documents in the form of the
`descriptive_elements` attribute, an array of `REXML::Element` objects. On calling
`save_to_xml` on the `StashWrapper` instance, these elements will be embedded in the
wrapper's `<st:stash_descriptive>` element.

### Full example

```ruby
require 'stash/wrapper'

ST = Stash::Wrapper

identifier = ST::Identifier.new(
  type: ST::IdentifierType::DOI,
  value: '10.14749/1407399498'
)

version = ST::Version.new(
  number: 1,
  date: Date.new(2013, 8, 18),
  note: 'Sample wrapped Datacite document'
)

license = ST::License::CC_BY

embargo = ST::Embargo.new(
  type: ST::EmbargoType::DOWNLOAD,
  period: '1 year',
  start_date: Date.new(2014, 8, 18),
  end_date: Date.new(2013, 8, 18)
)

inventory = ST::Inventory.new(
  files: [
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'
    ),
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'
    ),
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'
    ),
  ])

datacite_file = 'spec/data/wrapper/wrapper-2-payload.xml'
datacite_root = REXML::Document.new(File.read(datacite_file)).root

wrapper = ST::StashWrapper.new(
  identifier: identifier,
  version: version,
  license: license,
  embargo: embargo,
  inventory: inventory,
  descriptive_elements: [datacite_root]
)

wrapper_xml = wrapper.save_to_xml

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
puts formatter.write(wrapper_xml, '')
```
