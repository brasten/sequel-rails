require 'sequel-rails/setup'
require 'sequel-rails/storage'

namespace :db do

  task :load_models => :environment do
    FileList["app/models/**/*.rb"].each { |model| load model }
  end

  desc 'Create the database, load the schema, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:migrate', 'db:seed' ]

  # namespace :test do
  #   task :prepare do
  #     Rails.env = "test"
  #     Rake::Task["db:setup"].invoke
  #   end
  # end
  
  namespace :test do
    desc "Recreate the test database from the current schema.rb"
    task :load => 'db:test:purge' do
      db = Rails::Sequel.setup('test')
      Rake::Task['db:schema:load'].invoke(db)
    end

    desc 'Runs db:test:load'
    task :prepare => :load

    desc 'Empty the test database'
    task :purge => :environment do
      Rake::Task['db:drop'].invoke()
      Rake::Task['db:create'].invoke()
    end
    
    task :environment do
      Rails.env = 'test'
      Rake::Task['environment'].invoke()
    end
  end

  namespace :create do
    desc 'Create all the local databases defined in config/database.yml'
    task :all => :environment do
      Rails::Sequel.storage.create_all
    end
  end

  desc "Create the database(s) defined in config/database.yml for the current Rails.env - also creates the test database(s) if Rails.env.development?"
  task :create => :environment do
    Rails::Sequel.storage.create_environment(Rails::Sequel.configuration.environments[Rails.env])
    if Rails.env.development? && Rails::Sequel.configuration.environments['test']
      Rails::Sequel.storage.create_environment(Rails::Sequel.configuration.environments['test'])
    end
  end

  namespace :drop do
    desc 'Drop all the local databases defined in config/database.yml'
    task :all => :environment do
      Rails::Sequel.storage.drop_all
    end
  end

  desc "Drops the database(s) for the current Rails.env - also drops the test database(s) if Rails.env.development?"
  task :drop => :environment do
    Rails::Sequel.storage.drop_environment(Rails::Sequel.configuration.environments[Rails.env])
    if Rails.env.development? && Rails::Sequel.configuration.environments['test']
      Rails::Sequel.storage.drop_environment(Rails::Sequel.configuration.environments['test'])
    end
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  namespace :migrate do
    task :load => :environment do
      # FileList['db/migrate/*.rb'].each do |migration|
      #   load migration
      # end
    end

    desc 'Migrate up using migrations'
    task :up, :version, :needs => :load do |t, args|
      require 'sequel-rails/migrations'
      ::Rails::Sequel::Migrations.migrate_up!(args[:version])
    end

    desc 'Migrate down using migrations'
    task :down, :version, :needs => :load do |t, args|
      require 'sequel-rails/migrations'
      ::Rails::Sequel::Migrations.migrate_down!(args[:version])
    end
  end

  ##
  # TODO: deal with this at some point
  #
  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by Sequel."
    task :dump => :environment do
      Sequel.extension :schema_dumper

      File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", "w") do |file|
        file.puts Sequel::Model.db.dump_schema_migration
      end
    end

    desc "Load a schema.rb file into the database."
    task :load, :db, :needs => :environment do |t, args|
      args.with_defaults(:db => Sequel::Model.db)

      file = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
      if File.exists?(file) then
        Sequel.extension :migration
        schema_migration = eval(File.read(file))
        schema_migration.apply(args.db, :up)
      else
        abort "#{file} doesn't exist."
      end
    end
  end
  
  
  desc 'Migrate the database to the latest version'
  task :migrate => 'db:migrate:up'

  namespace :sessions do
    desc "Creates the sessions table for SequelStore"
    task :create => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.auto_migrate!
      puts "Created '#{::Rails::Sequel.configuration.environments[Rails.env]['database']}.sessions'"
    end

    desc "Clear the sessions table for SequelStore"
    task :clear => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.delete()
      puts "Deleted entries from '#{::Rails::Sequel.configuration.environments[Rails.env]['database']}.sessions'"
    end
  end
end

task 'test:prepare' => 'db:test:prepare'
