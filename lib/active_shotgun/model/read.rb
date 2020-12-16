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

      def initialize(new_attributes = {})
        new_attributes.slice(*self.class.shotgun_readable_fetched_attributes).each do |attribute, value|
          instance_variable_set("@#{attribute}", value)
        end
      end

      module ClassMethods
        def first
          sg_result = shotgun_client.first
          new(sg_result.attributes.to_h.merge(id: sg_result.id))
        end

        def find(id)
          sg_result = shotgun_client.find(id)
          new(sg_result.attributes.to_h.merge(id: sg_result.id))
        end
      end
    end
  end
end
