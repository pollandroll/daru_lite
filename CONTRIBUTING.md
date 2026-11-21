# Contributing guide

## Installing daru Lite development dependencies

daru Lite requires Ruby 3.4 or later. To install the dependencies:

``` bash
bundle install
```

Run the test suite (should be all green with pending tests):

  `bundle exec rspec`

While preparing your pull requests, don't forget to check your code with Rubocop:

  `bundle exec rubocop`

`bundle exec rake` runs both.

## Basic Development Flow

1. Create a new branch with `git checkout -b <branch_name>`.
2. Make your changes. Write tests covering every case how your feature will be used.
3. Try out these changes with `bundle exec rake console`.
4. Run the test suite with `bundle exec rake spec` and Rubocop with `bundle exec rake cop`.
5. Commit the changes, add a line to `History.md` and submit a pull request.

## Testing

Place the spec for a file at the same level and with the same intermediate directories: if the code lies in `lib/daru_lite/xyz/abc.rb`, its spec should lie in `spec/xyz/abc_spec.rb`.

## Releasing

See [ReleasePolicy.md](ReleasePolicy.md).

## Daru internals

To get an overview of certain internals inherited from daru and their implementation, go over [this blog post](http://v0dro.github.io/blog/2015/08/16/elaboration-on-certain-internals-of-daru/).
