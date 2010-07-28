# TODO: DRY these up
namespace :db do
  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by Sequel"
    task :dump do
      Sequel.extension :schema_dumper
      db = Sequel.connect(Rails.configuration.database_configuration[Rails.env])
      File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", "w") do |file|
        file.write(db.dump_schema_migration)
      end
      Rake::Task["db:schema:dump"].reenable
    end
    
    desc "Load a schema.rb file into the database"
    task :load do
      file = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
      if File.exists?(file)
        load(file)
      else
        abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/boot.rb to limit the frameworks that will be loaded}
      end
    end
  end

  namespace :create do
    desc 'Create all the local databases defined in config/database.yml'
    task :all do
      Rails.configuration.database_configuration.each_value do |config|
        next unless config['database']
        database = config.delete('database')
        DB = Sequel.connect(config)
        default_options = "DEFAULT CHARSET utf8 COLLATE utf8_unicode_ci"
        puts "Creating database \"#{config['database']}\" if it doesn't already exist"
        DB.run "CREATE DATABASE IF NOT EXISTS `#{config['database']}` /*!40100 #{default_options} */"
      end
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :create do
    connect_options = Rails.configuration.database_configuration[Rails.env]
    connect_options.delete('database')
    DB = Sequel.connect(connect_options)
    default_options = "DEFAULT CHARSET utf8 COLLATE utf8_unicode_ci"
    puts "Creating database \"#{Rails.configuration.database_configuration[Rails.env]['database']}\" if it doesn't already exist"
    DB.run "CREATE DATABASE IF NOT EXISTS `#{Rails.configuration.database_configuration[Rails.env]['database']}` /*!40100 #{default_options} */"
    if Rails.env.development? && Rails.configuration.database_configuration['test']
      puts "Creating database \"#{Rails.configuration.database_configuration['test']['database']}\" if it doesn't already exist"
      DB.run "CREATE DATABASE IF NOT EXISTS `#{Rails.configuration.database_configuration['test']['database']}` /*!40100 #{default_options} */"
    end
  end
  
  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml'
    task :all do
      Rails.configuration.database_configuration.each_value do |config|
        next unless config['database']
        database = config.delete('database')
        DB = Sequel.connect(config)
        puts "Dropping database #{database} if it exists"
        DB.run "DROP DATABASE IF EXISTS `#{database}`"
      end
    end
  end
  
  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :drop do
    connect_options = Rails.configuration.database_configuration[Rails.env]
    connect_options.delete('database')
    DB = Sequel.connect(connect_options)

    puts "Dropping database #{Rails.configuration.database_configuration[Rails.env]['database']} if it exists"
    DB.run "DROP DATABASE IF EXISTS `#{Rails.configuration.database_configuration[Rails.env]['database']}`"
  end

  namespace :migrate do
    task :load do
      require File.expand_path('../../sequel_migration', __FILE__)
    end

    desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :load do
      if ENV["VERSION"]
        Rake::Task["db:migrate:down"].invoke
        Rake::Task["db:migrate:up"].invoke
      else
        Rake::Task["db:rollback"].invoke
        Rake::Task["db:migrate"].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    task :reset => ["db:drop", "db:create", "db:migrate"]

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :load do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Sequel::Migrator.run(:up, "db/migrate/", version)
      Rake::Task["db:schema:dump"].invoke
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :load do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Sequel::Migrator.run(:down, "db/migrate/", version)
      Rake::Task["db:schema:dump"].invoke
    end
  end
  
  desc 'Migrate the database to the latest version'
  task :migrate => :'migrate:load' do
    Sequel::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.rollback('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke
  end

  desc 'Pushes the schema to the next version. Specify the number of steps with STEP=n'
  task :forward => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.forward('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke
  end
  
  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end
  
  desc 'Create the database, load the schema, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:migrate', 'db:seed' ]
  
  desc 'Drops and recreates the database from db/schema.rb for the current environment and loads the seeds.'
  task :reset => [ 'db:drop', 'db:setup' ]
  
  namespace :test do
    task :prepare => ['db:reset']
  end
end
