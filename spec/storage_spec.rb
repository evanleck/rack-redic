# encoding: UTF-8
# frozen_string_literal: true
require 'support/shared_examples/storage_marshaller'

describe Rack::Session::Redic::Storage do
  context 'using the default marshaller' do
    it_behaves_like 'a storage marshaller'

    subject do
      described_class.new(nil, Marshal, ENV['REDIS_URL'])
    end
  end
end
