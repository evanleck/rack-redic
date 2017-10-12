# encoding: UTF-8
# frozen_string_literal: true
require 'msgpack'
require_relative 'support/storage_marshaller_interface'

MessagePack::DefaultFactory.register_type(0x00, Symbol)

module MessagePackMarshaller
  def dump(object)
    MessagePack.pack(object)
  end
  module_function :dump

  def load(string)
    MessagePack.unpack(string)
  end
  module_function :load
end

describe Rack::Session::Redic::Storage do
  describe 'using the MessagePack as the marshaller' do
    include StorageMarshallerInterface

    before do
      @store = Rack::Session::Redic::Storage.new(nil, MessagePackMarshaller, ENV['REDIS_URL'])
    end
  end
end
