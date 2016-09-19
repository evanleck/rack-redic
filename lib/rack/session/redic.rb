# encoding: UTF-8
# frozen_string_literal: true
require 'rack/session/abstract/id'
require 'redic'
require 'zlib'

module Rack
  module Session
    #
    # Rack::Session::Redic provides simple cookie based session management.
    # Session data is stored in Redis via the Redic gem. The corresponding
    # session key is maintained in the cookie.
    #
    # You may optionally supply the class/module you would like to use when
    # marshalling objects in and out of Redis. All that is required is that
    # this class respond to the  `load` and `dump` methods, returning the
    # session hash and a string respectively.
    #
    # Addtionally, you may pass in the URL for your Redis server. The default
    # URL is fetched from the ENV as 'REDIS_URL' in keeping with Heroku and
    # others' practices.
    #
    # Any other options will get passed to Rack::Session::Abstract::Persisted.
    #
    class Redic < Abstract::Persisted
      def initialize(app, options = {})
        super

        @mutex = Mutex.new
        @marshaller = options.delete(:marshaller) { Marshal }
        @storage = StorageWrapper.new(@marshaller, options.delete(:url) { ENV.fetch('REDIS_URL') })
      end

      # Only accept a generated session ID if it doesn't exist.
      def generate_sid
        loop do
          sid = super
          break sid unless @storage.exists?(sid)
        end
      end

      # Find the session (or generate a blank one).
      def find_session(req, sid)
        @mutex.synchronize do
          unless sid and session = @storage.get(sid)
            sid, session = generate_sid, {}
            @storage.set(sid, session)
          end

          [sid, session]
        end
      end

      # Write the session.
      def write_session(req, session_id, new_session, options)
        @mutex.synchronize do
          @storage.set(session_id, new_session)

          session_id
        end
      end

      # Kill the session.
      def delete_session(req, session_id, options)
        @mutex.synchronize do
          @storage.delete(session_id)
          generate_sid unless options[:drop]
        end
      end

      private

      # Generic storage wrapper.
      #   Currently using Redis via Redic.
      class StorageWrapper
        DELETE = 'DEL'
        EXISTS = 'EXISTS'
        GET = 'GET'
        SET = 'SET'

        def initialize(marshaller, url)
          @marshaller = marshaller
          @storage = ::Redic.new(url)
        end

        def exists?(id)
          @storage.call(EXISTS, id) != 0
        end

        def get(id)
          deserialize(@storage.call(GET, id))
        end

        def set(id, object)
          @storage.call(SET, id, serialize(object))
        end

        def delete(id)
          @storage.call(DELETE, id)
        end

        private

        # Should always return a string.
        def serialize(object)
          [Zlib::Deflate.deflate(@marshaller.dump(object))].pack('m')
        end

        # Should always return the session object.
        def deserialize(string)
          return unless string
          @marshaller.load(Zlib::Inflate.inflate(string.unpack('m').first))
        end
      end
    end
  end
end
