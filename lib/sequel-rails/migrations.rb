require 'sequel/extensions/migration'

module Rails
  module Sequel
    class Migrations

      class << self
        
        def migrate_up!(version=nil)
          opts = {}
          opts[:target] = version.to_i if version
          
          
          
          ::Sequel::Migrator.run(::Sequel::Model.db, "db/migrate", opts)
        end
        
        def migrate_down!(version=nil)
          opts = {}
          opts[:target] = version.to_i if version

          ::Sequel::Migrator.run(::Sequel::Model.db, "db/migrate", opts)
        end
        
      end
      
      
    end
  end
end
