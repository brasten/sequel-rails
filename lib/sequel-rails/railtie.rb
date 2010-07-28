require 'sequel'

require 'rails'
require 'active_model/railtie'

# Comment taken from active_record/railtie.rb
#
# For now, action_controller must always be present with
# rails, so let's make sure that it gets required before
# here. This is needed for correctly setting up the middleware.
# In the future, this might become an optional require.
require 'action_controller/railtie'

require 'sequel-rails/setup'
require "sequel-rails/railties/log_subscriber"
require "sequel-rails/railties/i18n_support"


module Rails
  module Sequel

    class Railtie < Rails::Railtie

      ::Sequel::Railties::LogSubscriber.attach_to :sequel

      config.generators.orm :sequel, :migration => true

      rake_tasks do
        load 'sequel-rails/railties/database.rake'
      end

      initializer 'sequel.configuration' do |app|
        configure_sequel(app)
      end

      initializer 'sequel.logger' do |app|
        setup_logger(app, Rails.logger)
      end

      initializer 'sequel.i18n_support' do |app|
        setup_i18n_support(app)
      end

      # Expose database runtime to controller for logging.
      initializer "sequel.log_runtime" do |app|
        setup_controller_runtime(app)
      end

      # Run setup code after_initialize to make sure all config/initializers
      # are in effect once we setup the connection. This is especially necessary
      # for the cascaded adapter wrappers that need to be declared before setup.

      config.after_initialize do |app|
        setup_sequel(app)
      end




      # Support overwriting crucial steps in subclasses


      def configure_sequel(app)
        app.config.sequel = Rails::Sequel::Configuration.for(
          Rails.root, app.config.database_configuration
        )
      end

      def setup_i18n_support(app)
        ::Sequel::Model.send :include, Rails::Sequel::I18nSupport
      end

      def setup_controller_runtime(app)
        require "sequel-rails/railties/controller_runtime"
        ActionController::Base.send :include, Rails::Sequel::Railties::ControllerRuntime
      end

      def setup_logger(app, logger)
        app.config.sequel.logger=logger
      end

      module Setup

        def setup_sequel(app)
          # preload_lib(app)
          # preload_models(app)
          Rails::Sequel.setup(Rails.env)
        end

        # def preload_lib(app)
        #   app.config.paths.lib.each do |path|
        #     Dir.glob("#{path}/**/*.rb").sort.each do |file|
        #       require_dependency file unless file.match(/#{path}\/generators\/*/)
        #     end
        #   end
        # end
        # 
        # def preload_models(app)
        #   app.config.paths.app.models.each do |path|
        #     Dir.glob("#{path}/**/*.rb").sort.each { |file| require_dependency file }
        #   end
        # end

      end

      extend Setup

    end

  end
end
