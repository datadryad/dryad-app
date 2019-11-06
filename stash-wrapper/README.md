# stash-wrapper

[![Build Status](https://travis-ci.org/CDL-Dryad/stash-wrapper.svg?branch=master)](https://travis-ci.org/CDL-Dryad/stash-wrapper)
[![Code Climate](https://codeclimate.com/github/CDL-Dryad/stash-wrapper.svg)](https://codeclimate.com/github/CDL-Dryad/stash-wrapper)
[![Inline docs](http://inch-ci.org/github/CDL-Dryad/stash-wrapper.svg)](http://inch-ci.org/github/CDL-Dryad/stash-wrapper)
[![Gem Version](https://img.shields.io/gem/v/stash-wrapper.svg)](https://github.com/CDL-Dryad/stash-wrapper/releases)

Gem for working with the [Stash](https://github.com/CDL-Dryad/stash)
[XML wrapper format](https://dash.ucop.edu/stash_wrapper/stash_wrapper.xsd).

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

Note that [TypesafeEnum](https://github.com/dmolesUC3/typesafe_enum) classes are provided
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
  start_date: Date.new(2013, 8, 18),
  end_date: Date.new(2014, 8, 18)
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

## Generating sample data

The script `bin/gen_stash_wrapper_sample` will generate sample wrapper files with embedded
datacite metadata and [lorem ipsum](https://en.wikipedia.org/wiki/Lorem_ipsum)-style
placeholder content. With no arguments, it will generate one file and write it to standard
output; with a numeric argument, it will generate that number of files and write them to the
current working directory.

When generating multiple files, the script pulls from a relatively small pool of randomly
generated authors (1000), publishers (100), and resource types (20), so that files generated
in the same session will share some metadata field values. The MIME types of the `<file/>`
entries in a single session will also be pulled from a small subset (20) of real MIME types,
and the file extensions should match, but the MIME types, being randomly selected, are likely
to be nonsensical.

### Single file to standard output
```
% gen_stash_wrapper_sample
<st:stash_wrapper xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='https://dash.ucop.edu/stash_wrapper/ https://dash.ucop.edu/stash_wrapper/stash_wrapper.xsd' xmlns:st='https://dash.ucop.edu/stash_wrapper/'>
  <st:identifier type='DOI'>10.21585/def1000001</st:identifier>
  <st:stash_administrative>
    <st:version>
      <st:version_number>1</st:version_number>
      <st:date>2014-03-16Z</st:date>
      <st:note>Mecum noctem illam superiorem; iam intellege</st:note>
    </st:version>
    <st:license>
      <st:name>Creative Commons Attribution 4.0 International (CC BY 4.0)</st:name>
      <st:uri>https://creativecommons.org/licenses/by/4.0/</st:uri>
    </st:license>
    <st:embargo>
      <st:type>none</st:type>
      <st:period>none</st:period>
      <st:start>2014-03-16Z</st:start>
      <st:end>2014-03-16Z</st:end>
    </st:embargo>
    <st:inventory num_files='4'>
      <st:file>
        <st:pathname>nocte.mng</st:pathname>
        <st:size unit='B'>2244</st:size>
        <st:mime_type>video/x-mng</st:mime_type>
      </st:file>
      <st:file>
        <st:pathname>constrictam.htc</st:pathname>
        <st:size unit='B'>2228</st:size>
        <st:mime_type>text/x-component</st:mime_type>
      </st:file>
      <st:file>
        <st:pathname>teneri.plt</st:pathname>
        <st:size unit='B'>55719</st:size>
        <st:mime_type>application/vnd.hp-HPGL</st:mime_type>
      </st:file>
      <st:file>
        <st:pathname>oculis.uvg</st:pathname>
        <st:size unit='B'>8080</st:size>
        <st:mime_type>image/vnd.dece.graphic</st:mime_type>
      </st:file>
    </st:inventory>
  </st:stash_administrative>
  <st:stash_descriptive>
    <dcs:resource xmlns:dcs='http://datacite.org/schema/kernel-3' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://datacite.org/schema/kernel-3
                            http://schema.datacite.org/meta/kernel-3/metadata.xsd'>
      <dcs:identifier identifierType='DOI'>10.21585/def1000001</dcs:identifier>
      <dcs:creators>
        <dcs:creator>
          <dcs:creatorName>Interficiere Statum</dcs:creatorName>
          <dcs:creatorName>Armis Speculabuntur</dcs:creatorName>
          <dcs:creatorName>Iste Relinqueres Opimius</dcs:creatorName>
          <dcs:creatorName>Ordinis Vivis</dcs:creatorName>
        </dcs:creator>
      </dcs:creators>
      <dcs:titles>
        <dcs:title>Admirandum, dies</dcs:title>
      </dcs:titles>
      <dcs:publisher>Furorem Nostro Multis Mores Nocturnum Ahala Tam</dcs:publisher>
      <dcs:publicationYear>2014</dcs:publicationYear>
      <dcs:subjects>
        <dcs:subject>convenit</dcs:subject>
        <dcs:subject>domus</dcs:subject>
        <dcs:subject>neque</dcs:subject>
        <dcs:subject>ora</dcs:subject>
        <dcs:subject>paulo</dcs:subject>
        <dcs:subject>perniciosum</dcs:subject>
        <dcs:subject>poena</dcs:subject>
        <dcs:subject>res</dcs:subject>
        <dcs:subject>scientia</dcs:subject>
        <dcs:subject>tuorum</dcs:subject>
      </dcs:subjects>
      <dcs:resourceType resourceTypeGeneral='Dataset'>te</dcs:resourceType>
      <dcs:descriptions>
        <dcs:description descriptionType='Abstract'>
          Pridem oportebat, in te conferri pestem, quam tu in nos omnes iam diu
          machinaris. an vero vir amplissumus, scipio, pontifex maximus,
          gracchum mediocriter labefactantem statum rei publicae privatus
          interfecit; catilinam orbem terrae caede atque incendiis vastare
          cupientem nos consules perferemus? nam illa nimis antiqua praetereo,
          quod servilius ahala maelium novis rebus studentem manu sua occidit.
          fuit, fuit ista quondam in hac re publica virtus, ut viri.
        </dcs:description>
      </dcs:descriptions>
    </dcs:resource>
  </st:stash_descriptive>
</st:stash_wrapper>
```

### Multiple files
```
% cd /tmp
% gen_stash_wrapper_sample 10
/tmp/stash_wrapper-01.xml
/tmp/stash_wrapper-02.xml
/tmp/stash_wrapper-03.xml
/tmp/stash_wrapper-04.xml
/tmp/stash_wrapper-05.xml
/tmp/stash_wrapper-06.xml
/tmp/stash_wrapper-07.xml
/tmp/stash_wrapper-08.xml
/tmp/stash_wrapper-09.xml
/tmp/stash_wrapper-10.xml
```
