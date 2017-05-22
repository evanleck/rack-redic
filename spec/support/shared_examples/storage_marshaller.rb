# encoding: UTF-8
# frozen_string_literal: true
RSpec.shared_examples 'a storage marshaller' do
  it 'returns nil for empty keys' do
    expect(subject.get('not-here')).to eq(nil)
  end

  it 'saves objects' do
    object = { saved: true }
    subject.set('saving', object)

    expect(subject.get('saving')).to eq(object)
    subject.delete('saving') # Cleanup.
  end

  it 'checks the existence of keys' do
    subject.set('exists', false)

    expect(subject.exists?('exists')).to eq(true)
  end

  it 'deletes objects' do
    object = { deleted: true }
    subject.set('deleted', object)

    expect(subject.get('deleted')).to eq(object)
    subject.delete('deleted')

    expect(subject.get('deleted')).to eq(nil)
  end
end
