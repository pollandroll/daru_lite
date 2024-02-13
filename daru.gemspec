# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'daru/version.rb'

Daru::DESCRIPTION = <<MSG
Daru (Data Analysis in RUby) is a library for analysis, manipulation and visualization
of data. Daru works seamlessly accross interpreters and leverages interpreter-specific
optimizations whenever they are available.

It is the default data storage gem for all the statsample gems (glm, timeseries, etc.)
and can be used with many others like mixed_models, gnuplotrb and iruby.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'daru'
  spec.version       = Daru::VERSION
  spec.authors       = ['Sameer Deshmukh']
  spec.email         = ['sameer.deshmukh93@gmail.com']
  spec.summary       = %q{Data Analysis in RUby}
  spec.description   = Daru::DESCRIPTION
  spec.homepage      = "http://github.com/SciRuby/daru"
  spec.license       = 'BSD-2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'activerecord', '~> 6.0'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler', '>= 2.1.4'
  spec.add_development_dependency 'dbd-sqlite3'
  spec.add_development_dependency 'dbi'
  spec.add_development_dependency 'distribution', '~> 0.8'
  spec.add_development_dependency 'matrix'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'prime'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14.3'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.12.1'
  spec.add_development_dependency 'ruby-prof'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'spreadsheet', '~> 1.3.0'
  spec.add_development_dependency 'sqlite3'
  # issue : https://github.com/SciRuby/daru/issues/493 occured
  # with latest version of sqlite3
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard-junk'
end
