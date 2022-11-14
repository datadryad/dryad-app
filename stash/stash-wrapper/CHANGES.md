## 0.1.16 (14 November 2022)

- Upgrade ruby to 3.0

## 0.1.15 (30 September 2021)

- Ruby upgrade, rubocop fixes
- Update gems

## 0.1.14 (14 September 2020)

- Upgrade to ruby 2.4.10
- Rubocop fixes
- Move tests to main spec directory
- Upgrade to bundler and rubocop

## 0.1.13 (13 November 2019)

- Upgrade ruby to 2.4.4
- Test fixes (travis and rubocop)
- Gem security updates

## 0.1.12 (14 November 2018)

- Change stash-wrapper namespace URI to https://dash.ucop.edu/stash_wrapper/ and schema location to 
  https://dash.ucop.edu/stash_wrapper/stash_wrapper.xsd (formerly both URLs were http://dash.cdlib.org/)
- Update to Ruby 2.4.1
- Update to Rubocop 0.57.2
- Update dependencies

## 0.1.11.1 (5 August 2016)

- In `License::CC_BY`, use "Creative Commons Attribution 4.0 International (CC BY 4.0)" 
  as name, as per [summary](https://creativecommons.org/licenses/by/4.0/), instead of 
  "Creative Commons Attribution 4.0 International (CC-BY)".

## 0.1.11 (5 August 2016)

- In the convenience constant `License::CC_BY`, use the 
  [human-readable summary](https://creativecommons.org/licenses/by/4.0/) URL for the license 
  instead of the [legal code](https://creativecommons.org/licenses/by/4.0/legalcode).
- In the convenience constant `License::CC_ZERO`, use the 
  [human-readable summary](https://creativecommons.org/publicdomain/zero/1.0/) URL for the license 
  instead of the [legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

## 0.1.10 (28 July 2016)

- Added convenience constant `License::CC_ZERO` for the
  [CC0](https://creativecommons.org/publicdomain/zero/1.0/legalcode) public domain declaration
- Allow `License` to take a string as a `uri` parameter, so long as that string is a valid URI
- Validate parameters for:
  - `StashWrapper`
  - `StashAdministrative` (fixes issue #2)
  - `Embargo`
  - `Identifier`
  - `Inventory`
  - `Size`
  - `Version`

## 0.1.9 (18 May 2016)

- Update to XML::MappingExtensions 0.4.1

## 0.1.8 (17 May 2016)

- Update to XML::MappingExtensions 0.4.0

## 0.1.7 (2 May 2016)

- Fix issue where namespace would not be set correctly when round-tripping from XML

## 0.1.6 (2 May 2016)

- Update to XML::MappingExtensions 0.3.6 and remove now-unnecessary namespace hacks
- Update to TypesafeEnum 0.1.7 for improved debug output

## 0.1.5 (28 April 2016)

- Update to XML::MappingExtensions 0.3.5 to fix issues with `Date.xmlschema` misbehaving
  in a Rails / ActiveSupport environment

## 0.1.4 (25 April 2016)

- Replace all `require_relative` with absolute `require` to avoid symlink issues

## 0.1.3 (19 April 2016)

- Add convenience method `StashWrapper.file_names` to return a list of filenames
  from the inventory

## 0.1.2 (31 March 2016)

- Add convenience method `Embargo.none` to create a no-embargo embargo element
- Make `StashAdministrative` (and thereby `StashWrapper`) default to `Embargo.none`
  if no `Embargo` is provided

## 0.1.1 (16 March 2016)

- Fix gem metadata

## 0.1.0 (16 March 2016)

- Initial release
