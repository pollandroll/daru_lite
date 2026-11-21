require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:cop)

task default: %i[spec cop]

desc 'Open an IRB session with daru_lite loaded'
task :console do
  sh 'irb -I lib -r daru_lite'
end
