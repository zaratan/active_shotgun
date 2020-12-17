# frozen_string_literal: true

module ActiveShotgun
  module Model
    module Associations
      def self.included(base_class)
        base_class.const_set(:BELONG_ASSOC, [])
        base_class.const_set(:MANY_ASSOC, [])
      end

      module ClassMethods
        def belongs_to(assoc_name, klass: nil, types: nil, type: nil)
          klass ||= assoc_name.to_s.camelize
          types ||= [type].flatten if type
          types ||= [assoc_name.to_s.camelize]
          types = [types].flatten.map(&:to_s)
          # define name_id
          # define name that read and populate the class
          instance_eval do
            # Register the association
            self::BELONG_ASSOC.push(assoc_name)

            # Define the id reader
            attr_reader "#{assoc_name}_id"

            # Define the id writter
            define_attribute_methods("#{assoc_name}_id")
            define_method("#{assoc_name}_id=") do |value, new_type = nil|
              send("#{assoc_name}_id_will_change!")
              if new_type
                unless types.include?(new_type)
                  raise "Invalid Type #{new_type}. Valid types are: [#{types.join(', ')}]"
                end

                instance_variable_set("@#{assoc_name}_type", new_type)
              elsif types.size == 1
                instance_variable_set("@#{assoc_name}_type", types.first)
              else
                unless public_send("#{assoc_name}_type")
                  raise "Multiple types possible. You must specify a type from [#{types.join(', ')}]"
                end
              end
              instance_variable_set("@#{assoc_name}_id", value)
            end

            # Define the type reader
            attr_reader "#{assoc_name}_type"

            # Define the assoc reader
            define_method(assoc_name) do
              instance_variable_get("@#{assoc_name}") ||
                instance_variable_set(
                  "@#{assoc_name}",
                  (klass.is_a?(String) ? klass.constantize : klass).
                  parse_shotgun_results(
                    Client.
                    shotgun.
                    entities(public_send("#{assoc_name}_type")).
                    find(public_send("#{assoc_name}_id"))
                  )
                )
            end

            define_method("#{assoc_name}=") do |assoc_item|
              public_send("#{assoc_name}_id=", assoc_item.id, assoc_item.class.shotgun_type)
              instance_variable_set("@#{assoc_name}", assoc_item)
            end
          end
        end

        def has_many(assoc_name_plural, possible_types: nil)
          assoc_name = assoc_name_plural.to_s.singularize
          possible_types ||= {
            assoc_name.camelize => assoc_name.camelize,
          }
          if possible_types.is_a?(Array)
            possible_types.map do |type|
              [
                type.camelize,
                type.camelize,
              ]
            end.to_h
          end
          # define name that read and populate an array of (a query ?)

          instance_eval do
            # Register the association
            self::MANY_ASSOC.push(assoc_name_plural)

            # Define reader must return an AssociationQuery which override push/<</delete with instant remove/add
            define_method(assoc_name_plural) do
              instance_variable_get("@#{assoc_name_plural}") ||
                instance_variable_set(
                  "@#{assoc_name_plural}",
                  AssociationsProxy.new(
                    possible_types: possible_types,
                    base_class: self.class,
                    base_id: id,
                    field_name: assoc_name_plural
                  ).where(
                    [
                      self.class.shotgun_type.downcase.to_s.pluralize,
                      "is",
                      {
                        type: self.class.shotgun_type.camelize,
                        id: id,
                      },
                    ]
                  )
                )
            end

            # Define writer
            define_attribute_methods(assoc_name_plural)
            define_method("#{assoc_name_plural}=") do |array|
              send("#{assoc_name_plural}_will_change!")
              instance_variable_set("@#{assoc_name_plural}", array)
            end
          end
        end
      end
    end
  end
end
