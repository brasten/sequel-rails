module Rails
  module Sequel

    def self.storage
      Storage
    end

    class Storage
      attr_reader :config

      def self.create_all
        with_local_repositories { |config| create_environment(config) }
      end

      def self.drop_all
        with_local_repositories { |config| drop_environment(config) }
      end

      def self.create_environment(config)
        new(config).create
      end

      def self.drop_environment(config)
        new(config).drop
      end

      def self.new(config)
        config = Rails::Sequel.configuration.environments[config.to_s] unless config.kind_of?(Hash)
        
        klass = lookup_class(config['adapter'])
        if klass.equal?(self)
          super(config)
        else
          klass.new(config)
        end
      end

      class << self
      private

        def with_local_repositories
          Rails::Sequel.configuration.environments.each_value do |config|
            if config['host'].blank? || %w[ 127.0.0.1 localhost ].include?(config['host'])
              yield(config)
            else
              puts "This task only modifies local databases. #{config['database']} is on a remote host."
            end
          end
        end

        def lookup_class(adapter)
          klass_name = adapter.camelize.to_sym

          unless Storage.const_defined?(klass_name)
            raise "Adapter #{adapter} not supported (#{klass_name.inspect})"
          end

          const_get(klass_name)
        end

      end

      def initialize(config)
        @config = config
      end

      def create
        _create
        puts "[sequel] Created database '#{database}'"
      end

      def drop
        _drop
        puts "[sequel] Dropped database '#{database}'"
      end

      def database
        @database ||= config['database'] || config['path']
      end

      def username
        @username ||= config['username'] || ''
      end

      def password
        @password ||= config['password'] || ''
      end

      def charset
        @charset ||= config['charset'] || ENV['CHARSET'] || 'utf8'
      end

      class Sqlite < Storage
        def _create
          return if in_memory?
          ::Sequel.connect(config.merge('database' => path))
        end

        def _drop
          return if in_memory?
          path.unlink if path.file?
        end

      private

        def in_memory?
          database == ':memory:'
        end

        def path
          @path ||= Pathname(File.expand_path(database, Rails.root))
        end

      end

      class Mysql < Storage
        def _create
          execute("CREATE DATABASE IF NOT EXISTS `#{database}` DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}")
        end

        def _drop
          execute("DROP DATABASE IF EXISTS `#{database}`")
        end

      private

        def execute(statement)
          system(
            'mysql',
            (username.blank? ? '' : "--user=#{username}"),
            (password.blank? ? '' : "--password=#{password}"),
            '-e',
            statement
          )
        end

        def collation
          @collation ||= config['collation'] || ENV['COLLATION'] || 'utf8_unicode_ci'
        end

      end

      class Postgres < Storage
        def _create
          system(
            'createdb',
            '-E',
            charset,
            '-U',
            username,
            database
          )
        end

        def _drop
          system(
            'dropdb',
            '-U',
            username,
            database
          )
        end
      end
      
      class Jdbc < Storage
        
        def _is_mysql?
          database.match(/^jdbc:mysql/)
        end
        
        def _root_url
          database.scan /^jdbc:mysql:\/\/\w*:?\d*/
        end
        
        def db_name
          database.scan(/^jdbc:mysql:\/\/\w+:?\d*\/(\w+)/).flatten.first
        end
        
        def _params
          database.scan /\?.*$/
        end
        
        def _create
          if _is_mysql?
            ::Sequel.connect("#{_root_url}#{_params}") do |db|
              db.execute("CREATE DATABASE IF NOT EXISTS `#{db_name}` DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}")
            end
          end
        end

        def _drop
          if _is_mysql?
            ::Sequel.connect("#{_root_url}#{_params}") do |db|
              db.execute("DROP DATABASE IF EXISTS `#{db_name}`")
            end
          end
        end
        
        private
        
        def collation
          @collation ||= config['collation'] || ENV['COLLATION'] || 'utf8_unicode_ci'
        end
        
        
      end
      
    end
  end
end
