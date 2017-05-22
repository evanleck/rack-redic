# encoding: UTF-8
# frozen_string_literal: true

# Ensure we have this set before trying to initialize anything.
ENV['REDIS_URL'] ||= 'redis://localhost:6379'

# Require our core library.
require 'rack/session/redic'
