require 'sequel'

# Implements Sequel-specific session store.

module Rails
  module Sequel

    class SessionStore < ActionDispatch::Session::AbstractStore

      class Session < ::Sequel::Model

        # property :id,         Serial
        # property :session_id, String,   :required => true, :unique => true, :unique_index => true
        # property :data,       Object,   :required => true, :default => ActiveSupport::Base64.encode64(Marshal.dump({}))
        # property :updated_at, DateTime, :required => false, :index => true

        class << self

          def auto_migrate!
            self.db.create_table :sessions do
              primary_key :id
              column :session_id, String,
                     :null    => false,
                     :unique  => true,
                     :index   => true

              column :data, :text,
                     :null => false

              column :updated_at, DateTime,
                     :null => true,
                     :index => true
            end
          end

          def marshal(data)
            ActiveSupport::Base64.encode64(Marshal.dump(data)) if data
          end

          def unmarshal(data)
            Marshal.load(ActiveSupport::Base64.decode64(data)) if data
          end
        end

        def self.name
          'session'
        end

        def data
          self[:data] ||= self.class.unmarshal(self[:data]) || {}
        end

        def marshal_data!
          return false unless self[:data]
          self[:data] = self.class.marshal(data)
        end

        def before_save
          marshal_data!
          super
        end
      end

      SESSION_RECORD_KEY = 'rack.session.record'.freeze

      cattr_accessor :session_class
      self.session_class = Session

      private

      def get_session(env, sid)
        sid ||= generate_sid
        session = find_session(sid)
        env[SESSION_RECORD_KEY] = session
        [ sid, session.data ]
      end

      def set_session(env, sid, session_data)
        session            = get_session_resource(env, sid)
        session.data       = session_data
        session.updated_at = Time.now if session.modified?
        session.save
      end

      def get_session_resource(env, sid)
        if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
          env[SESSION_RECORD_KEY] = find_session(sid)
        else
          env[SESSION_RECORD_KEY] ||= find_session(sid)
        end
      end

      def find_session(sid)
        klass = self.class.session_class

        klass.where(:session_id => sid).first || klass.new(:session_id => sid)
      end

    end

  end
end
