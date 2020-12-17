# frozen_string_literal: true

module ActiveShotgun
  module Model
    module Read
      def attributes
        self.class.shotgun_readable_fetched_attributes.map do |attribute|
          [attribute, instance_variable_get("@#{attribute}")]
        end.to_h
      end

      def writable_attributes
        self.class.shotgun_writable_fetched_attributes.map do |attribute|
          [attribute, instance_variable_get("@#{attribute}")]
        end.to_h
      end

      def initialize(new_attributes = {}, new_relations = {})
        new_attributes.slice(*self.class.shotgun_readable_fetched_attributes).each do |attribute, value|
          instance_variable_set("@#{attribute}", value)
        end
        self.class::BELONG_ASSOC.each do |assoc|
          next unless relation = new_relations[assoc]

          instance_variable_set("@#{assoc}_type", relation["type"])
          instance_variable_set("@#{assoc}_id", relation["id"])
          instance_variable_set("@#{assoc}", nil)
        end
      end

      def reload
        self.class.find(id)
      end

      module ClassMethods
        def all
          prepare_new_query.all
        end

        def limit(number)
          prepare_new_query.limit(number)
        end

        def offset(number)
          prepare_new_query.limit(number)
        end

        def first(number = 1)
          prepare_new_query.first(number)
        end

        def where(conditions)
          prepare_new_query.where(conditions)
        end

        def find_by(conditions)
          prepare_new_query.find_by(conditions)
        end

        def orders(new_orders)
          prepare_new_query.orders(new_orders)
        end

        def prepare_new_query
          Query.new(type: shotgun_type, klass: self)
        end

        def find(id)
          sg_result = shotgun_client.find(id)
          parse_shotgun_results(sg_result)
        end

        def count
          prepare_new_query.count
        end

        def size
          prepare_new_query.size
        end

        def parse_shotgun_results(sg_result)
          new(
            sg_result.attributes.to_h.merge(id: sg_result.id),
            sg_result.relationships.transform_values{ |v| v["data"] }.with_indifferent_access
          )
        end
      end
    end
  end
end
