require 'active_support/core_ext/hash/except'

require 'sequel/extensions/migration'

require 'sequel-rails/configuration'
require 'sequel-rails/runtime'
require 'sequel-rails/railties/benchmarking_mixin'

module Rails
  module Sequel
    @databases = {}
	
    def self.setup(environment)
      config = ::Rails::Sequel.configuration.environment_for(environment.to_s)
      ::Sequel.connect({:logger => configuration.logger}.merge(config))
    end
	
    def self.database(name)
      @databases[name] ||= setup(name)
    end
  end
end
