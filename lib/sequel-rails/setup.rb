require 'active_support/core_ext/hash/except'

require 'sequel/extensions/migration'

require 'sequel-rails/configuration'
require 'sequel-rails/railties/benchmarking_mixin'

module Rails
  module Sequel

    def self.setup(environment)
      puts "[datamapper] Setting up the #{environment.inspect} environment:"

      ::Sequel.connect({:logger => configuration.logger}.merge(::Rails::Sequel.configuration.environments[environment.to_s]))
    end

  end
end
