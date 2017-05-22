# encoding: UTF-8
# frozen_string_literal: true
require 'rack/session/abstract/id'
require 'redic'

module Rack
  module Session
    #
    # Rack::Session::Redic provides simple cookie based session management.
    # Session data is stored in Redis via the Redic gem. The corresponding
    # session key is maintained in the cookie.
    #
    # Options include:
    #
    # - :marshaller - You may optionally supply the class/module you would
    #   like to use when marshalling objects in and out of Redis. All that is
    #   required is that this class respond to the  `load` and `dump` methods,
    #   returning the session hash and a string respectively.
    # - :url - Addtionally, you may pass in the URL for your Redis server. The
    #   default URL is fetched from the ENV as 'REDIS_URL' in keeping with
    #   Heroku and others' practices.
    # - :expire_after - Finally, expiration will be passed to the Redis server
    #   via the 'EX' option on 'SET'. Expiration should be in seconds, just like
    #   Rack's default handling of the :expire_after option. This option will
    #   refresh the expiration set in Redis with each request.
    #
    # Any other options will get passed to Rack::Session::Abstract::Persisted.
    #
    class Redic < Abstract::Persisted
      REDIS_URL = 'REDIS_URL'.freeze

      attr_reader :storage

      def initialize(app, options = {})
        super

        @mutex = Mutex.new
        @storage = Storage.new(
          options[:expire_after],
          options.fetch(:marshaller) { Marshal },
          options.fetch(:url) { ENV.fetch(REDIS_URL) }
        )
      end

      # Only accept a generated session ID if it doesn't exist.
      def generate_sid
        loop do
          sid = super
          break sid unless @storage.exists?(sid)
        end
      end

      # Find the session (or generate a blank one).
      def find_session(_req, sid)
        @mutex.synchronize do
          unless sid && session = @storage.get(sid)
            sid, session = generate_sid, {}
          end

          [sid, session]
        end
      end

      # Write the session.
      def write_session(_req, session_id, new_session, _options)
        @mutex.synchronize do
          @storage.set(session_id, new_session)

          session_id
        end
      end

      # Kill the session.
      def delete_session(_req, session_id, options)
        @mutex.synchronize do
          @storage.delete(session_id)
          generate_sid unless options[:drop]
        end
      end

      ##
      # A wrapper around Redic to simplify calls.
      class Storage
        # Redis commands.
        DELETE = 'DEL'.freeze
        EX = 'EX'.freeze
        EXISTS = 'EXISTS'.freeze
        GET = 'GET'.freeze
        SET = 'SET'.freeze

        # Assorted.
        PACK = 'm'.freeze
        ZERO = 0

        def initialize(expires, marshaller, url)
          @expires = expires
          @marshaller = marshaller
          @storage = ::Redic.new(url)
        end

        def exists?(id)
          @storage.call(EXISTS, id) != ZERO
        end

        def get(id)
          deserialize(@storage.call(GET, id))
        end

        def set(id, object)
          arguments = [SET, id, serialize(object)]
          arguments += [EX, @expires] if @expires

          @storage.call(*arguments)
        end

        def delete(id)
          @storage.call(DELETE, id)
        end

        private

        # Should always return a string.
        def serialize(object)
          @marshaller.dump(object)
        end

        # Should always return the session object.
        def deserialize(string)
          @marshaller.load(string) if string

        # In the case that loading fails, return a nil.
        rescue
          nil
        end
      end
    end
  end
end
