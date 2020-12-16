# frozen_string_literal: true

require 'active_model'

module ActiveShotgun
  module Model
    def self.included(base_class)
      base_class.include(ActiveModel::Validations)
      base_class.extend(ActiveModel::Callbacks)
      base_class.include(ActiveModel::Dirty)
      base_class.include(ActiveModel::Serialization)
      base_class.include(ActiveModel::Serializers::JSON)
      base_class.extend(ActiveModel::Naming)

      name = base_class.name
      fetched_attributes = Client.fetch_field_names_for_an_entity_type(name)

      writable_fetched_attributes = fetched_attributes[:writable]
      readable_fetched_attributes = fetched_attributes[:readable]

      base_class.instance_eval do
        define_attribute_methods(*writable_fetched_attributes)
        attr_reader(*readable_fetched_attributes, *writable_fetched_attributes)

        define_singleton_method(:shotgun_type) do
          name
        end

        define_singleton_method(:shotgun_readable_fetched_attributes) do
          readable_fetched_attributes
        end

        define_singleton_method(:shotgun_writable_fetched_attributes) do
          writable_fetched_attributes
        end

        define_singleton_method(:shotgun_client) do
          Client.shotgun.entities(shotgun_type)
        end

        define_method(:shotgun_client) do
          self.class.shotgun_client
        end

        writable_fetched_attributes.each do |attribute|
          define_method("#{attribute}=") do |value|
            send("#{attribute}_will_change!")
            instance_variable_set("@#{attribute}", value)
          end
        end
      end

      base_class.include(Read)
      base_class.extend(Read::ClassMethods)
      base_class.include(Write)
      base_class.extend(Write::ClassMethods)
      base_class.include(Delete)
      base_class.extend(Delete::ClassMethods)
      base_class.prepend(Validations)
      base_class.prepend(Callbacks)
    end

    module Write
      def persisted?
        !!id
      end

      def save
        return false unless changed?

        sg_result =
          if persisted?
            shotgun_client.update(id, changes.transform_values(&:last))
          else
            shotgun_client.create(changes.transform_values(&:last))
          end
        override_attributes!(sg_result.attributes.to_h.merge(id: sg_result.id))
        changes_applied
        true
      end
      alias_method :save!, :save

      def mass_assign(assigned_attributes)
        assigned_attributes.
          transform_keys(&:to_sym).
          slice(*self.class.shotgun_writable_fetched_attributes).
          each do |k, v|
            public_send("#{k}=", v)
          end
      end

      def update(updated_attributes)
        mass_assign(updated_attributes)
        save
      end

      def update!(updated_attributes)
        mass_assign(updated_attributes)
        save!
      end

      module ClassMethods
        def create(create_attributes)
          new_entity = new
          new_entity.mass_assign(create_attributes)
          new_entity.save
        end

        def create!(create_attributes)
          new_entity = new
          new_entity.mass_assign(create_attributes)
          new_entity.save!
        end
      end

      private

      def override_attributes!(new_attributes)
        new_attributes.
          transform_keys(&:to_sym).
          slice(*self.class.shotgun_readable_fetched_attributes).
          each do |k, v|
            instance_variable_set("@#{k}", v)
          end
      end
    end

    module Validations
      def save
        validate && super
      end

      def save!
        validate!
        super
      end
    end

    module Callbacks
      def self.prepended(base)
        base.define_model_callbacks :destroy
        base.define_model_callbacks :update
        base.define_model_callbacks :save
        base.define_model_callbacks :create
        base.define_model_callbacks :validation
      end

      def destroy
        run_callbacks(:destroy) do
          super
        end
      end

      def save
        run_callbacks(:save) do
          run_callbacks(persisted? ? :update : :create) do
            super
          end
        end
      end

      def validate
        run_callbacks(:validation) do
          super
        end
      end
    end

    module Delete
      def delete
        shotgun_client.delete(id)
      end
      alias_method :destroy, :delete

      module ClassMethods
        def revive(id)
          shotgun_client.revive(id)
        end
      end
    end

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
