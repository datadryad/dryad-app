## 0.2.0 (6 April 2017)

- add support for embargoes in `stash-wrapper.xml` and `mrt-embargo.txt`
- update to reflect new DB schema with StashEngine::Author replacing
  StashDatacite::Creator

## 0.1.1 (23 February 2017)

- fix issue where uploads from previous versions would be re-added to zipfiles
  for later versions
- fix issue where missing file uploads would not be logged / reported correctly
  due to incorrect initialization of ArgumentError

## 0.1.0 (3 February 2017)

- initial release
