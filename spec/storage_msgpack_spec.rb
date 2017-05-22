# encoding: UTF-8
# frozen_string_literal: true
require 'support/shared_examples/storage_marshaller'
require 'msgpack'

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
  context 'using the MessagePack as the marshaller' do
    it_behaves_like 'a storage marshaller'

    subject do
      Rack::Session::Redic::Storage.new(nil, MessagePackMarshaller, ENV['REDIS_URL'])
    end
  end
end
