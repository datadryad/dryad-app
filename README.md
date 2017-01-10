# Stash::Merritt

[![Build Status](https://travis-ci.org/CDLUC3/stash-merritt.svg?branch=master)](https://travis-ci.org/CDLUC3/stash-merritt) 
[![Code Climate](https://codeclimate.com/github/CDLUC3/stash-merritt.svg)](https://codeclimate.com/github/CDLUC3/stash-merritt) 
[![Inline docs](http://inch-ci.org/github/CDLUC3/stash-merritt.svg)](http://inch-ci.org/github/CDLUC3/stash-merritt)

Packaging and
[SWORD 2.0](http://swordapp.github.io/SWORDv2-Profile/SWORDProfile.html)
deposit module for submitting
[Stash](https://github.com/CDLUC3/stash_engine) datasets to
[Merritt](http://www.cdlib.org/uc3/merritt/).

## Submission process

1. mint a new DOI with EZID, if not already present
1. generate:
   - Datacite XML, including DOI
   - Stash wrapper XML
   - Dublin Core metadata XML
   - DataONE manifest
   - `mrt-delete.txt`, if needed
1. create ZIP archive including:
   - Datacite XML
   - Stash wrapper XML
   - DublinCore XML
   - DataONE manifest
   - `mrt-delete.txt`, if present
   - all user-uploaded files
1. submit to SWORD
1. determine landing page URL based on DOI
1. submit Datacite XML and landing page URL to EZID
1. clean up temporary files


