# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'beaker-gke/version'

Gem::Specification.new do |s|
  s.name        = 'beaker-gke'
  s.version     = BeakerGke::VERSION
  s.authors     = ["Night's Watch"]
  s.email       = ['team-nw@puppet.com']
  s.homepage    = 'https://github.com/puppetlabs/beaker-gke'
  s.summary     = 'Beaker hypervisor for GKE!'
  s.description = 'Add GKE support to Beaker acceptance testing tool'
  s.license     = 'Apache-2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |file| File.basename(file) }
  s.require_paths = ['lib']

  # required ruby version
  s.required_ruby_version = '~> 2.3'

  # Run time dependencies
  s.add_runtime_dependency 'googleauth', '~> 0.9'
  s.add_runtime_dependency 'kubeclient', '~> 4.4.0'
end
