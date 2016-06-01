# 0.2.0 (next)

- Validate parameters for:
  - `StashWrapper`
  - `StashAdministrative` (fixes issue #2)
  - `Embargo`
  - `Identifier`
  - `Version`

# 0.1.9 (18 May 2016)

- Update to XML::MappingExtensions 0.4.1

# 0.1.8 (17 May 2016)

- Update to XML::MappingExtensions 0.4.0

# 0.1.7 (2 May 2016)

- Fix issue where namespace would not be set correctly when round-tripping from XML

# 0.1.6 (2 May 2016)

- Update to XML::MappingExtensions 0.3.6 and remove now-unnecessary namespace hacks
- Update to TypesafeEnum 0.1.7 for improved debug output

# 0.1.5 (28 April 2016)

- Update to XML::MappingExtensions 0.3.5 to fix issues with `Date.xmlschema` misbehaving
  in a Rails / ActiveSupport environment

# 0.1.4 (25 April 2016)

- Replace all `require_relative` with absolute `require` to avoid symlink issues

# 0.1.3 (19 April 2016)

- Add convenience method `StashWrapper.file_names` to return a list of filenames
  from the inventory

# 0.1.2 (31 March 2016)

- Add convenience method `Embargo.none` to create a no-embargo embargo element
- Make `StashAdministrative` (and thereby `StashWrapper`) default to `Embargo.none`
  if no `Embargo` is provided

# 0.1.1 (16 March 2016)

- Fix gem metadata

# 0.1.0 (16 March 2016)

- Initial release
