require 'test_helper'

module Nin
  class FakeStore
    def read
      {
        Date.today.prev_day.to_s => [
          {
            'id' => 1,
            'desc' => 'Fake Task 1 desc',
            'tags' => ['fake_tag'],
            'completed' => false,
            'archived' => false
          }
        ],
        Date.today.to_s => [
          {
            'id' => 2,
            'desc' => 'Fake Task 2 desc',
            'tags' => ['school'],
            'completed' => true,
            'archived' => false
          },
          {
            'id' => 3,
            'desc' => 'Fake Task 3 desc',
            'tags' => [],
            'completed' => false,
            'archived' => false
          },
          {
            'id' => 4,
            'desc' => 'Fake Task 4 desc',
            'tags' => [],
            'completed' => false,
            'archived' => false
          }
        ],
        Date.today.succ.to_s => [
          {
            'id' => 5,
            'desc' => 'Fake Task 5 desc',
            'tags' => ['fake_tag'],
            'completed' => true,
            'archived' => true
          }
        ]
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

    def test_initialize_orders_items_by_date
      assert ascending?(@todo.items, :date)
    end

    def test_list_archived_only_by_default
      expected = @todo.items.select { |item| !item.archived? }.map do |item|
        item.to_s << "\n"
      end.join

      assert_output(expected) { @todo.list }
    end

    def test_list_all_with_archived
      @todo.instance_variable_set(:@options, { archived: true })

      expected = @todo.items.map do |item|
        item.to_s << "\n"
      end.join

      assert_output(expected) { @todo.list }
    end

    def test_add
      old_item_count = @todo.items.count
      last_id        = @todo.items.sort_by(&:id).last.id

      return_msg  = @todo.add('Fake Task 5 desc', nil, [])
      new_last_id = @todo.send(:last_id)

      assert_equal 1, @todo.items.count - old_item_count
      assert_equal 1, new_last_id - last_id
      assert_equal last_id + 1, new_last_id
      assert_equal 'Wrote to store successfully', return_msg
    end

    def test_add_first_item
      @todo.items = []

      return_msg = @todo.add('Fake Task 1', nil, ['school'])

      assert_equal 1, @todo.items.count
      assert_equal 1, @todo.items.first.id
      assert_equal 'Wrote to store successfully', return_msg
    end

    def test_edit
      return_msg = @todo.edit(3, 'Fake Task 3 desc editd', nil, [])

      assert_equal 'Fake Task 3 desc editd', @todo.items.find_by(:id, 3).desc
      assert_equal 'Wrote to store successfully', return_msg
    end

    def test_edit_not_found
      assert_raises ItemNotFoundError do
        @todo.edit(50, 'Not Found Fake Task', nil, [])
      end
    end

    def test_complete
      @todo.complete(3)

      assert @todo.items.find_by(:id, 3).completed?
    end

    def test_complete_not_found
      assert_raises ItemNotFoundError do
        @todo.complete(50)
      end
    end

    def test_complete_multiple_items
      @todo.complete(1, 4)

      assert @todo.items.find_by(:id, 1).completed?
      assert @todo.items.find_by(:id, 4).completed?
    end

    def test_archive
      id = @todo.items.find_by(:id, 1).id

      @todo.archive(id)


      assert @todo.items.find_by(:id, 1).archived?
    end

    def test_archive_not_found
      assert_raises ItemNotFoundError do
        @todo.archive(50)
      end
    end

    def test_archive_multiple_items
      @todo.archive(1, 2)

      assert @todo.items.find_by(:id, 1).archived?
      assert @todo.items.find_by(:id, 2).archived?
    end

    def test_delete_archived
      old_item_count      = @todo.items.count
      archived_item_count = @todo.send(:archived_items).count

      @todo.delete_archived

      assert_equal archived_item_count, old_item_count - @todo.items.count
      assert_equal @todo.items.map(&:id), (1..@todo.items.count).to_a
    end

    def test_delete
      old_item_count = @todo.items.count
      @todo.delete(2)

      assert_equal 1, old_item_count - @todo.items.count
    end

    def test_delete_not_found
      assert_raises ItemNotFoundError do
        @todo.delete(50)
      end
    end

    def test_delete_multiple_items
      old_item_count = @todo.items.count
      @todo.delete(2, 3)

      assert_equal 2, old_item_count - @todo.items.count
    end
  end
end
