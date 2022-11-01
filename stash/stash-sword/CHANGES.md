## 0.1.11 (1 November 2022)

- Upgrade to ruby 2.7.6

## 0.1.10 (27 September 2022)

- Add async support, cleanup, use logger instead of logs, rubocop fixes

## 0.1.9 (27 January 2021)

- Updates to ruby, database, rubocop, warning fixes

## 0.1.8 (14 September 2020)

- Update to ruby 2.4.10, rubocop changes, moving tests, bundler upgrade, rubocop upgrade

## 0.1.7 (14 November 2019)

- Update to ruby 2.4.4, rubocop fixes

## 0.1.6 (23 February 2017)

- Support choosing binary packaging instead of zip.

## 0.1.5 (21 November 2016)

- Pass `read_timeout` and `open_timeout` explicitly for clarity.

## 0.1.4 (14 November 2016)

- Update to Ruby 2.2.5
- Add `timeout:` parameter to `HTTPHelper`, with a default of 10 minutes.

## 0.1.3 (15 August 2016)

- Use 2.0.0 release version of `rest-client` to fix issues with cookie handling in redirection

## 0.1.2 (11 July 2016)

- Use `Content-disposition: attachment` (per [SWORD spec](http://swordapp.github.io/SWORDv2-Profile/SWORDProfile.html))
  instead of `form-data`, now that Merritt supports it properly.

## 0.1.1 (23 June 2016)

- `logger` is now a parameter passed to `Stash::Sword::Client` instead of a global singleton.

## 0.1.0 (8 June 2016)

- Initial release.
