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
  end
end
