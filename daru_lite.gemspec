# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'daru_lite/version.rb'

DaruLite::DESCRIPTION = <<MSG
Daru (Data Analysis in RUby) is a library for analysis, manipulation and visualization
of data. Daru works seamlessly accross interpreters and leverages interpreter-specific
optimizations whenever they are available.

It is the default data storage gem for all the statsample gems (glm, timeseries, etc.)
and can be used with many others like mixed_models, gnuplotrb and iruby.

Daru Lite is a fork of Daru that aims to focus on data manipulation and stability.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'daru_lite'
  spec.version       = DaruLite::VERSION
  spec.authors       = ['Thomas Naude-Filonnière', 'Maxime Lasserre', 'Julie Thomas', 'Amar Slaoua', 'Mourtada Belhantri']
  spec.summary       = %q{Data Analysis in RUby, stripped down}
  spec.description   = DaruLite::DESCRIPTION
  spec.homepage      = "https://github.com/pollandroll/daru"
  spec.license       = 'BSD-2-Clause'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'activerecord', '~> 6.0'
  spec.add_development_dependency 'awesome_print', '~> 1.9.2'
  spec.add_development_dependency 'bundler', '~> 2.1', '>= 2.1.4'
  spec.add_development_dependency 'dbd-sqlite3', '~> 1.2.5'
  spec.add_development_dependency 'dbi', '~> 0.4.5'
  spec.add_development_dependency 'distribution', '~> 0.8'
  spec.add_development_dependency 'matrix', '~> 0.4.2'
  spec.add_development_dependency 'nokogiri', '~> 1.16.2'
  spec.add_development_dependency 'prime', '~> 0.1.2'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'pry-byebug', '~> 3.10.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rspec-its', '~> 1.3.0'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20.2'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.25'
  spec.add_development_dependency 'ruby-prof', '~> 1.7.0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'spreadsheet', '~> 1.3.0'
  spec.add_development_dependency 'sqlite3', '~> 1.7.2'
  # issue : https://github.com/SciRuby/daru/issues/493 occured
  # with latest version of sqlite3
  spec.add_development_dependency 'webmock', '~> 3.20.0'
end
