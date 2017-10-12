# encoding: UTF-8
# frozen_string_literal: true
module StorageMarshallerInterface
  def test_returns_nil_for_empty_keys
    assert_nil @store.get('not-here')
  end

  def test_saves_objects
    object = { saved: true }
    @store.set('saving', object)

    assert_equal @store.get('saving'), object
  end

  def test_existence_of_keys
    @store.set('exists', false)

    assert_equal @store.exists?('exists'), true
  end

  def test_deletes_objects
    object = { deleted: true }
    @store.set('deleted', object)

    assert_equal @store.get('deleted'), object
    @store.delete('deleted')

    assert_nil @store.get('deleted')
  end
end
