require 'sequel-rails/setup'
require 'sequel-rails/storage'

namespace :db do

  task :load_models => :environment do
    FileList["app/models/**/*.rb"].each { |model| load model }
  end

  desc 'Create the database, load the schema, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:automigrate', 'db:seed' ]

  namespace :test do
    task :prepare => ['db:setup']
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


  desc 'Perform destructive automigration of all repositories in the current Rails.env'
  task :automigrate => :load_models do
    Rails::Sequel.configuration.environments[Rails.env].each do |repository, config|
      ::Sequel.auto_migrate!(repository.to_sym)
      puts "[datamapper] Finished auto_migrate! for :#{repository} repository '#{config['database']}'"
    end
    if Rails.env.development? && Rails::Sequel.configuration.environments['test']
      Rails::Sequel.setup('test')
      Rails::Sequel.configuration.environments['test'].each do |repository, config|
        ::Sequel.auto_migrate!(repository.to_sym)
        puts "[datamapper] Finished auto_migrate! for :#{repository} repository '#{config['database']}'"
      end
    end
  end

  desc 'Perform non destructive automigration of all repositories in the current Rails.env'
  task :autoupgrade => :load_models do
    Rails::Sequel.configuration.environments[Rails.env].each do |repository, config|
      ::Sequel.auto_upgrade!(repository.to_sym)
      puts "[datamapper] Finished auto_upgrade! for :#{repository} repository '#{config['database']}'"
    end
    if Rails.env.development? && Rails::Sequel.configuration.environments['test']
      Rails::Sequel.setup('test')
      Rails::Sequel.configuration.environments['test'].each do |repository, config|
        ::Sequel.auto_upgrade!(repository.to_sym)
        puts "[datamapper] Finished auto_upgrade! for :#{repository} repository '#{config['database']}'"
      end
    end
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  namespace :migrate do
    task :load => :environment do
      require 'sequel/extensions/migration'
      FileList['db/migrate/*.rb'].each do |migration|
        load migration
      end
    end

    desc 'Migrate up using migrations'
    task :up, :version, :needs => :load do |t, args|
      ::Sequel::MigrationRunner.migrate_up!(args[:version])
    end

    desc 'Migrate down using migrations'
    task :down, :version, :needs => :load do |t, args|
      ::Sequel::MigrationRunner.migrate_down!(args[:version])
    end
  end

  desc 'Migrate the database to the latest version'
  task :migrate => 'db:migrate:up'

  namespace :sessions do
    desc "Creates the sessions table for SequelStore"
    task :create => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.auto_migrate!
      puts "Created '#{Rails::Sequel.configurations[Rails.env]['database']}.sessions'"
    end

    desc "Clear the sessions table for SequelStore"
    task :clear => :environment do
      require 'sequel-rails/session_store'
      Rails::Sequel::SessionStore::Session.all.destroy!
      puts "Deleted entries from '#{Rails::Sequel.configurations[Rails.env]['database']}.sessions'"
    end
  end

end
