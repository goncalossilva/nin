require 'test_helper'

require 'nin/item'
require 'nin/todo'

module Nin
  class FakeStore
    def read
      {
        1 => { 'desc' => 'Fake Task 1 desc' },
        2 => { 'desc' => 'Fake Task 2 desc' }
      }
    end

    def write(hash)
      'Wrote to store successfully'
    end
  end

  class TodoTest < Minitest::Test
    def setup
      @store = FakeStore.new()
      @todo  = Nin::Todo.new(@store)
    end

    def test_initialize_loads_items
      refute_empty @todo.items
    end

    def test_list
      output = capture_stdout { @todo.list }

      assert_equal "1: Fake Task 1 desc\n2: Fake Task 2 desc\n", output
    end

    def test_add
      return_msg = @todo.add('Fake Task 3 desc')

      assert_equal 3, @todo.items.count
      assert_equal 3, @todo.items.last.id
      assert_equal 'Wrote to store successfully', return_msg
    end

    def test_add_first_item
      @todo.items = []

      return_msg = @todo.add('Fake Task 1')

      assert_equal 1, @todo.items.count
      assert_equal 1, @todo.items.first.id
      assert_equal 'Wrote to store successfully', return_msg
    end

    def test_delete
      @todo.delete(2)

      assert_equal 1, @todo.items.count
    end
  end
end
