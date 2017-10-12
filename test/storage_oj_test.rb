# encoding: UTF-8
# frozen_string_literal: true
require 'oj'
require_relative 'support/storage_marshaller_interface'

describe Rack::Session::Redic::Storage do
  describe 'using the Oj as the marshaller' do
    include StorageMarshallerInterface

    before do
      @store = Rack::Session::Redic::Storage.new(nil, Oj, ENV['REDIS_URL'])
    end
  end
end
