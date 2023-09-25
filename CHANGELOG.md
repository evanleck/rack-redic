# Changelog

## 2.2.0

Add support for and test against both Rack v2 and v3.

## 2.1.0

Pin runtime dependency versions, especially for
[rack](https://github.com/rack/rack) since they've recently released v3.0.0
which this gem has not yet been tested against.

## 2.0.1

Fix a bug where `ENV.fetch(REDIS_URL)` would get evaluated even when it wasn't
needed. ([#1](https://github.com/evanleck/rack-redic/pull/1))

This change was contributed by
[@andreasgassnerwen](https://github.com/andreasgassnerwen)

## 2.0.0

- Drop support for Ruby versions less than 2.5.
- Add GitHub Actions testing.
- Remove the mutex around the find, write, and delete operations.

## 1.4.1

Use `push` in `#write_session` instead of `+=`.

## 1.4.0

- Refactor out the additional storage class.
- Remove UTF-8 encoding magic comments.
- Don't freeze already frozen strings.
- Fix the implementation of `#find_session`.
- Add RuboCop.

## 1.2.0 and 1.3.0

No effective changes, just documentation updates. Not very SEMVER of me...

## 1.1.0

Rescue deserialization errors and return `nil`.

## 1.0.0

Initial release.
