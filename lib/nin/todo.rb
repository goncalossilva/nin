module Nin
  class Todo
    attr_accessor :items
    attr_reader :store

    def initialize(config, options = {})
      @store             = config.fetch(:store)
      @integrated_client = config.fetch(:integrated_client, nil)
      @options           = options
      @items             = load_items_sorted
    end

    def list
      items_to_list = if @options[:archived]
                        @items
                      else
                        unarchived_items
                      end

      puts Presenter::TodoPresenter.new(items_to_list).call
    end

    def add(desc, date, tags)
      @items << Item.new(next_id, desc, date, tags)

      @store.write(to_hash)
    end

    def edit(id, desc, date, tags)
      item = find_by_id(id)

      item.edit(desc, date, tags)

      @store.write(to_hash)
    end

    def prioritize(id, step = 1)
      item_to_prioritize = find_by_id(id)
      item_group         = @items.group_by(&:date)[item_to_prioritize.date]

      new_id, actual_step = item_group.map(&:id).round_shift(id, step)
      step_sign           = actual_step > 0 ? +1 : -1

      items_to_reprioritize = item_group.where(:id) do |item_id|
        step_sign * item_id < step_sign * id
      end.limit(actual_step)

      item_to_prioritize.id = new_id
      items_to_reprioritize.each { |item| item.id += step_sign }

      @store.write(to_hash)
    end

    def complete(*ids)
      ids.each do |id|
        item = find_by_id(id.to_i)
        item.toggle_completed!
      end

      @store.write(to_hash)
    end

    def archive(*ids)
      ids.each do |id|
        item = find_by_id(id.to_i)
        item.toggle_archived!
      end

      @store.write(to_hash)
    end

    def delete_archived
      delete(*archived_items.map(&:id))

      reset_item_indices!
    end

    def delete(*ids)
      ids.each do |id|
        item = find_by_id(id.to_i)
        @items.delete(item)
      end

      reset_item_indices!
    end

    def analyze
      items_to_analyze = @items.where(:completed, true)

      histogram = items_to_analyze.group_by(&:date).map { |k, v| [k, v.size] }
      histogram.each do |date, size|
        puts "#{date} : #{'*' * size}"
      end
    end

    def sync_down
      id = next_id
      @integrated_client.fetch.each do |t|
        item          = Item.new(id, *t)
        existing_item = @items.find_by(:uid, item.uid)

        if existing_item
          t.delete_at(3)
          existing_item.edit(*t)
        else
          @items << item

          id += 1
        end
      end

      @store.write(to_hash)
    end

    private

    def load_items_sorted
      load_items.sort_by { |item| [item.date, item.id] }
    end

    def load_items
      items = []
      @store.read.map do |key, values|
        date = key.dup
        values.map do |item|
          items << Item.new(item.fetch('id').to_i,
                            item.fetch('desc'),
                            date,
                            item.fetch('tags'),
                            item.fetch('uid', nil),
                            item.fetch('completed'),
                            item.fetch('archived'))
        end
      end

      items
    end

    def archived_items
      @items.where(:archived?, true)
    end

    def unarchived_items
      @items.where(:archived?, false)
    end

    def find_by_id(id)
      found_item = @items.find_by(:id, id)

      raise ItemNotFoundError unless found_item

      found_item
    end

    def to_hash
      groupped_items.reduce({}) do |hash, (date, items)|
        hash.update(date => items.map(&:to_h))
      end
    end

    def groupped_items
      @items.group_by { |item| item.date.to_s }
    end

    def next_id
      last_id + 1
    end

    def last_id
      begin
        @items.sort_by(&:id).last.id
      rescue NoMethodError
        0
      end
    end

    def reset_item_indices!
      @items.each.with_index(1) do |item, index|
        item.id = index
      end

      @store.write(to_hash)
    end
  end
end
