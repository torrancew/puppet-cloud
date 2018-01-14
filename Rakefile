require 'rubygems'
require 'puppet-lint'
require 'puppetlabs_spec_helper/rake_tasks'

# Disable unwanted checks
['80chars'].each do |chk|
  PuppetLint.configuration.send('disable_%s' % [chk])
end

task :ci => [:validate, :lint, :spec, :beaker]

task :doc do
  sh 'bundle exec puppet strings generate ./**/*.pp'
end
