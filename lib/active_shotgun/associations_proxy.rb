# frozen_string_literal: true

module ActiveShotgun
  class AssociationsProxy
    def initialize(base_class:, base_id:, field_name:, possible_types: {})
      @base_class = base_class
      @base_id = base_id
      @field_name = field_name
      @possible_types = possible_types
      @queries =
        possible_types.map do |type, klass|
          Query.new(type: type, klass: klass)
        end
      @global_limit = 1000
      @global_offset = 0
      @global_orders = nil
      @global_fields = nil
    end

    def push(model)
      already_here =
        @queries.reduce([]) do |result, query|
          result + query.dup.limit(1000).pluck(:id).map{ |id|
                     { type: query.instance_variable_get(:@type), id: id }
                   }
        end
      Client.shotgun.entities(@base_class.to_s).update(
        @base_id,
        @field_name => already_here.push(
          {
            type: model.class.shotgun_type,
            id: model.id,
          }
        ).uniq
      )
      @array = nil
      true
    end
    alias_method :<<, :push

    def delete(id, type = nil)
      raise "Many types possible. Please specify." if !type && has_many_types?

      type ||= @possible_types.keys.first
      already_here =
        @queries.reduce([]) do |result, query|
          result + query.dup.limit(1000).pluck(:id).map{ |item_id|
                     { type: query.instance_variable_get(:@type), id: item_id }
                   }
        end
      new_items = already_here.reject{ |item| item[:type] == type && item[:id] == id }

      Client.shotgun.entities(@base_class.to_s).update(
        @base_id,
        @field_name => new_items.uniq
      )
      @array = nil
      true
    end

    def has_many_types?
      @has_many_types ||= @queries.size > 1
    end

    def all
      @array ||= resolve_all_queries # rubocop:disable Naming/MemoizedInstanceVariableName
    end
    alias_method :to_a, :all

    def first(number = 1)
      results = limit(number).all
      if @global_limit == 1
        results.first
      else
        results
      end
    end

    def limit(number)
      @global_limit = number
      @queries =
        @queries.map do |query|
          has_many_types? ? query.limit(1000) : query.limit(number)
        end
      self
    end

    def offset(number)
      @global_offset = number
      @queries =
        @queries.map do |query|
          has_many_types? ? query : query.offset(number)
        end
      @array = nil
      self
    end

    def where(conditions)
      @queries =
        @queries.map do |query|
          query.where(conditions)
        end
      @array = nil
      self
    end

    def find_by(conditions)
      where(conditions).first
    end

    def orders(new_orders)
      @global_orders = new_orders
      @queries =
        @queries.map do |query|
          query.orders(new_orders)
        end
      @array = nil
      self
    end

    def select(*fields)
      @queries =
        @queries.map do |query|
          query.select(fields)
        end
      @array = nil
      self
    end

    def pluck(*fields)
      fields.flatten!
      result = select(fields).map{ |e| fields.map{ |field| e.public_send(field) } }
      fields.size == 1 ? result.flatten : result
    end

    extend Forwardable
    def_delegators(
      :all,
      :each,
      :size,
      :count
    )
    include Enumerable

    private

    def global_orders_to_h
      case @global_orders
      when Hash # rubocop:disable Lint/EmptyWhen
      when Array
        @global_orders.map do |str|
          [str.gsub(/^[-+]/, '').to_sym, str.start_with?('-') ? :desc : :asc]
        end
      when String
        @global_orders = @global_orders.split(/\s*,\s*/)
        global_orders_to_h
      else
        raise "Unknown order type"
      end
    end

    def sort_results(results)
      orders = global_orders_to_h
      results.sort do |a, b|
        orders.reduce(0) do |res, order|
          if res == 0
            field = order.first
            if order.last == :asc
              a.public_send(field) <=> b.public_send(field)
            else
              b.public_send(field) <=> a.public_send(field)
            end
          else
            res
          end
        end
      end
    end

    def resolve_all_queries
      if has_many_types?
        results = @queries.flat_map(&:to_a)
        results = sort_results(results)
        results.shift(@global_offset).first(@global_limit)
      else
        @queries.flat_map(&:to_a)
      end
    end
  end
end
