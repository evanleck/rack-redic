# encoding: UTF-8
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
      # Redis commands.
      DELETE = 'DEL'.freeze
      EX = 'EX'.freeze
      EXISTS = 'EXISTS'.freeze
      GET = 'GET'.freeze
      SET = 'SET'.freeze

      # Assorted.
      REDIS_URL = 'REDIS_URL'.freeze
      ZERO = 0

      def initialize(app, options = {})
        super

        @expires = options[:expire_after]
        @marshaller = options.fetch(:marshaller) { Marshal }
        @mutex = Mutex.new
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
      def find_session(_req, sid)
        @mutex.synchronize do
          [sid || generate_sid, deserialize(@storage.call(GET, sid)) || {}]
        end
      end

      # Write the session.
      def write_session(_req, session_id, new_session, _options)
        arguments = [SET, session_id, serialize(new_session)]
        arguments += [EX, @expires] if @expires

        @mutex.synchronize do
          @storage.call(*arguments)

          session_id
        end
      end

      # Kill the session.
      def delete_session(_req, session_id, options)
        @mutex.synchronize do
          @storage.call(DELETE, session_id)
          generate_sid unless options[:drop]
        end
      end

      # Serialize an object using our marshaller.
      #
      # @param object [Object]
      # @return [String]
      #   The object serialized by the marshaller.
      def serialize(object)
        @marshaller.dump(object)
      end
      private :serialize

      # Deserialize a string back into an object.
      #
      # @param string [String]
      # @return [Object, nil]
      #   Returns the object as loaded by the marshaller, or nil.
      def deserialize(string)
        @marshaller.load(string) if string

      # In the case that loading fails, return a nil.
      rescue
        nil
      end
      private :deserialize
    end
  end
end
