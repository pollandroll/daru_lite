# Gem Release Policy

## Versioning

daru Lite follows [semantic versioning](http://semver.org/): the version number is always in the form MAJOR.MINOR.PATCH.

* Patch bump = Bug fixes
* Minor bump = New features but backwards compatible
* Major bump = API breaking changes

## Releasing

1. Bump `DaruLite::VERSION` in `lib/daru_lite/version.rb`.
2. Rename the `# Unreleased` heading at the top of `History.md` to the new version, and check that it lists every change.
3. Merge to `master` once CI is green.
4. Run `bundle exec rake release` from `master`: it tags the commit, builds the gem and pushes it to rubygems.org.
5. Publish a GitHub release for the tag.

## Release Timing

Patch releases should be done after every fix of a major bug.
Major releases should be kept to the minimum.
