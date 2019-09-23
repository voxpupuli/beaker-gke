# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'beaker-gke/version'

Gem::Specification.new do |s|
  s.name        = "beaker-gke"
  s.version     = BeakerGke::VERSION
  s.authors     = ["Night's Watch"]
  s.email       = ["team-nw@puppet.com"]
  s.homepage    = "https://github.com/puppetlabs/beaker-gke"
  s.summary     = %q{Beaker hypervisor for GKE!}
  s.description = %q{For use for the Beaker acceptance testing tool}
  s.license     = 'Apache2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Testing dependencies
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its'
  # pin fakefs for Ruby < 2.3
  if RUBY_VERSION < "2.3"
    s.add_development_dependency 'fakefs', '~> 0.6', '< 0.14'
  else
    s.add_development_dependency 'fakefs', '~> 0.6'
  end
  s.add_development_dependency 'rake', '~> 10.1'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pry', '~> 0.10'

  # Documentation dependencies
  s.add_development_dependency 'yard'
  s.add_development_dependency 'markdown'
  s.add_development_dependency 'thin'

  # Run time dependencies
  s.add_runtime_dependency 'kubeclient', '~> 4.4.0'
  s.add_runtime_dependency 'jsonpath'
  s.add_runtime_dependency 'googleauth'

end