# frozen_string_literal: true

require 'beaker'
require 'simplecov'
require 'climate_control'
require 'fakefs/spec_helpers'

Dir.glob(Dir.pwd + '/lib/beaker/hypervisor/*.rb').sort { |file| require file }

# setup & require beaker's spec_helper.rb
beaker_gem_spec = Gem::Specification.find_by_name('beaker')
beaker_gem_dir = beaker_gem_spec.gem_dir
beaker_spec_path = File.join(beaker_gem_dir, 'spec')
$LOAD_PATH << beaker_spec_path
require File.join(beaker_spec_path, 'spec_helper.rb')

RSpec.configure do |config|
  config.include TestFileHelpers
  config.include HostHelpers
end

def with_modified_env(options, &block)
  ClimateControl.modify(options, &block)
end
