# frozen_string_literal: true
require_relative 'helper'

# Require all test files.
Dir.glob('test/*.rb').each(&method(:require))
