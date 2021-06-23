# frozen_string_literal: true
require 'rack/session/abstract/id'
require 'redic'
require 'securerandom'

module Rack
  module Session
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
    class Redic < Abstract::Persisted
      HASH = {}.freeze

      # Redis commands.
      DELETE = 'DEL'
      EX = 'EX'
      EXISTS = 'EXISTS'
      GET = 'GET'
      SET = 'SET'

      # Assorted.
      REDIS_URL = 'REDIS_URL'
      ZERO = 0

      # Access the storage interface directly. Needed for testing.
      #
      # @return [Redic]
      attr_reader :storage

      def initialize(app, options = HASH)
        super(app, options)

        @expires = options[:expire_after]
        @marshaller = options.fetch(:marshaller) { Marshal }
        @storage = ::Redic.new(options.fetch(:url) { ENV.fetch(REDIS_URL) })
      end

      # Generate a session ID that doesn't already exist.
      #
      # Based on Rack::Session::Abstract::Persisted#generate_sid and
      # Rack::Session::Memcache#generate_sid but without the conditional check.
      # We always generate the session ID from SecureRandom#hex.
      #
      # @return [String]
      def generate_sid
        loop do
          session_id = SecureRandom.hex(@sid_length)
          break session_id unless @storage.call(EXISTS, session_id) != ZERO
        end
      end

      # Find the session (or generate a blank one).
      def find_session(_req, session_id)
        unless session_id && (session = deserialize(@storage.call(GET, session_id)))
          session_id, session = generate_sid, {} # rubocop:disable Style/ParallelAssignment
        end

        [session_id, session]
      end

      # Write the session.
      def write_session(_req, session_id, session_data, _options)
        arguments = [SET, session_id, serialize(session_data)]
        arguments.push(EX, @expires) if @expires

        @storage.call(*arguments)

        session_id
      end

      # Kill the session.
      def delete_session(_req, session_id, options)
        @storage.call(DELETE, session_id)

        generate_sid unless options[:drop]
      end

      private

      # Serialize an object using our marshaller.
      #
      # @param object [Object]
      # @return [String]
      #   The object as serialized by the marshaller.
      def serialize(object)
        @marshaller.dump(object)
      end

      # Deserialize a string back into an object.
      #
      # @param string [String]
      # @return [Object, nil]
      #   Returns the object as loaded by the marshaller, or nil.
      def deserialize(string)
        @marshaller.load(string) if string

      # In the case that loading fails, return a nil.
      rescue # rubocop:disable Lint/RescueStandardError
        nil
      end
    end
  end
end
