# coding: utf-8
require_relative 'lib/daru_lite/version'

description = <<~MSG
  Daru Lite is a library for data analysis and manipulation in Ruby, built around
  two data structures: the DataFrame and the Vector.

  It is a fork of Daru (Data Analysis in RUby) that focuses on data manipulation and
  stability, without the plotting features and the heavy native dependencies.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'daru_lite'
  spec.version       = DaruLite::VERSION
  spec.authors       = ['Thomas Naude-Filonnière', 'Maxime Lasserre', 'Julie Thomas', 'Amar Slaoua', 'Mourtada Belhantri']
  spec.summary       = %q{Data Analysis in RUby, stripped down}
  spec.description   = description
  spec.homepage      = "https://github.com/pollandroll/daru_lite"
  spec.license       = 'BSD-2-Clause'

  spec.required_ruby_version = '>= 3.4'

  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/master/History.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = `git ls-files -z -- lib LICENSE README.md History.md`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency 'csv', '>= 3.2.2'
  spec.add_dependency 'matrix', '>= 0.4'

  spec.add_development_dependency 'awesome_print', '~> 1.9'
  spec.add_development_dependency 'debug', '>= 1.0.0'
  spec.add_development_dependency 'distribution', '~> 0.8'
  spec.add_development_dependency 'prime', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rspec-its', '~> 2.0'
  spec.add_development_dependency 'rubocop', '~> 1.92.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.27.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.10.0'
  spec.add_development_dependency 'ruby-prof', '~> 2.0'
  spec.add_development_dependency 'simplecov', '~> 1.3'
  spec.add_development_dependency 'simplecov_json_formatter', '~> 0.1'
  spec.add_development_dependency 'webmock', '~> 3.25'
end
