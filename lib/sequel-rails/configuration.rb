require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/class/attribute_accessors'

module Rails
  module Sequel

    mattr_accessor :configuration

    class Configuration

      def self.for(root, database_yml_hash)
        Rails::Sequel.configuration ||= new(root, database_yml_hash)
      end

      attr_reader :root, :raw
      attr_accessor :logger
      attr_accessor :migration_dir

      def environment_for(name)
        environments[name.to_s] || environments[name.to_sym]
      end

      def environments
        @environments ||= @raw.inject({}) do |normalized, environment|
          name, config = environment.first, environment.last
          normalized[name] = normalize_repository_config(config)
          normalized
        end
      end

    private

      def initialize(root, database_yml_hash)
        @root, @raw = root, database_yml_hash
      end

      def normalize_repository_config(hash)
        config = {}
        hash.each do |key, value|
          config[key] = 
            if key == 'port'
              value.to_i
            elsif key == 'adapter' && value == 'sqlite3'
              'sqlite'
            elsif key == 'database' && (hash['adapter'] == 'sqlite3' || hash['adapter'] == 'sqlite')
              value == ':memory:' ? value : File.expand_path(hash['database'], root)
            else
              value
            end
        end
        
        config
      end

    end

  end
end
