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
    task :load, :needs => :environment do
      require 'sequel-rails/storage'
      Rails::Sequel::Storage.new(Rails.env).create

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
    task :all, :needs => :environment do
      require 'sequel-rails/storage'
      Rails::Sequel::Storage.create_all
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :create, :env, :needs => :environment do |t, args|
    args.with_defaults(:env => Rails.env)

    require 'sequel-rails/storage'
    Rails::Sequel::Storage.new(args.env).create

    if Rails.env.development? && Rails.configuration.database_configuration['test']
      Rails::Sequel::Storage.new('test').create
    end
  end

  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml'
    task :all, :needs => :environment do
      require 'sequel-rails/storage'
      Rails::Sequel::Storage.drop_all
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :drop, :env, :needs => :environment do |t, args|
    args.with_defaults(:env => Rails.env)

    require 'sequel-rails/storage'
    Rails::Sequel::Storage.new(args.env).drop

    if Rails.env.development? && Rails.configuration.database_configuration['test']
      Rails::Sequel::Storage.new('test').drop
    end
  end

  namespace :migrate do
    task :load => :environment do
      require 'sequel-rails/migrations'
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
      Rails::Sequel::Migrations.migrate_up!(version)
      Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :load do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Rails::Sequel::Migrations.migrate_down!(version)
      Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
    end
  end

  desc 'Migrate the database to the latest version'
  task :migrate => :'migrate:load' do
    Rails::Sequel::Migrations.migrate_up!(ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.rollback('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
  end

  desc 'Pushes the schema to the next version. Specify the number of steps with STEP=n'
  task :forward => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.forward('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
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
    task :prepare do
      Rails.env = 'test'
      Rake::Task['db:reset'].invoke()
      Sequel::DATABASES.each do |db|
        db.disconnect
      end
    end
  end

  namespace :sessions do
    desc "Creates the sessions table for SequelStore"
    task :create => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.auto_migrate!
      database = Rails::Sequel.configuration.environments[Rails.env]['database']
      puts "Created '#{database}.sessions'"
    end

    desc "Clear the sessions table for SequelStore"
    task :clear => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.delete
      database = Rails::Sequel.configuration.environments[Rails.env]['database']
      puts "Deleted entries from '#{database}.sessions'"
    end
  end
end

task 'test:prepare' => 'db:test:prepare'
