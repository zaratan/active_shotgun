# frozen_string_literal: true

module ActiveShotgun
  class Query
    def initialize(type:, klass:)
      @type = type
      @klass = klass.is_a?(String) ? klass.constantize : klass
      @conditions = nil
      @limit = 100
      @offset = 0
      @orders = nil
      @fields = nil
    end

    extend Forwardable
    def_delegators(
      :to_a,
      :each,
      :size,
      :count
    )
    include Enumerable

    def all
      page_calc = format_page_from_limit_and_offset(@limit, @offset)
      results = shotgun_client.all(
        fields: @fields,
        sort: @orders,
        filter: @conditions,
        page: page_calc[:page],
        page_size: page_calc[:page_size]
      )
      results.pop(page_calc[:end_trim])
      results.shift(page_calc[:start_trim])

      results.map{ |result| @klass.parse_shotgun_results(result) }
    end
    alias_method :to_a, :all

    def first(number = 1)
      results = limit(number).all
      if @limit == 1
        results.first
      else
        results
      end
    end

    def limit(number)
      @limit = number
      self
    end

    def offset(number)
      @offset = number
      self
    end

    def where(conditions)
      @conditions ||= {}
      @conditions =
        case conditions
        when Hash
          case @conditions
          when Hash
            @conditions.merge(conditions)
          when Array
            @conditions + translate_hash_contitions_to_array(conditions)
          else
            raise "Unknow type. Please use Hash or Array conditions"
          end
        when Array
          case @conditions
          when Hash
            translate_hash_contitions_to_array(@conditions) +
            if conditions.first.is_a? Array
              conditions
            else
              [conditions]
            end
          when Array
            @conditions +
            if conditions.first.is_a? Array
              conditions
            else
              [conditions]
            end
          else
            raise "Unknow type. Please use Hash or Array conditions"
          end
        else
          @conditions
        end
      self
    end

    def find_by(conditions)
      where(conditions).first
    end

    def orders(new_orders)
      @orders = new_orders
      self
    end

    def select(*fields)
      @fields = fields.flatten
      self
    end

    def pluck(*fields)
      fields.flatten!
      result = select(fields).map{ |e| fields.map{ |field| e.public_send(field) } }
      fields.size == 1 ? result.flatten : result
    end

    private

    def translate_hash_contitions_to_array(hash_conditions)
      hash_conditions.map do |k, v|
        [k, "is", v]
      end
    end

    def format_page_from_limit_and_offset(limit, offset)
      min = (offset + 1).to_f
      max = (offset + limit).to_f
      limit.upto(limit + offset) do |size|
        next unless (min / size).ceil == (max / size).ceil

        page = (min / size).ceil
        start_trim = min - (page - 1) * size - 1
        end_trim = page * size - max
        return {
          page_size: [size, 1000].min,
          page: page,
          start_trim: start_trim.to_i,
          end_trim: end_trim.to_i,
        }
      end
    end

    def shotgun_client
      Client.shotgun.entities(@type)
    end
  end
end
