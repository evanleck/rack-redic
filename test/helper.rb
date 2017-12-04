# frozen_string_literal: true

# Add our project folder to the root of our load path.
$LOAD_PATH.unshift File.expand_path('../..', __FILE__)

# Ensure we have this set before trying to initialize anything.
ENV['REDIS_URL'] ||= 'redis://localhost:6379'

# Require our core library.
require 'rack/session/redic'

# Kick off the tests.
require 'minitest/autorun'
