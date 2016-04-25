# 0.1.5 (Next)

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
