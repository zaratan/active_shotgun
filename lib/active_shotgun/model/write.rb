# frozen_string_literal: true

module ActiveShotgun
  module Model
    module Write
      def persisted?
        !!id
      end

      def save
        return false unless changed?

        sg_result =
          if persisted?
            shotgun_client.update(id, changes_with_relations)
          else
            shotgun_client.create(changes_with_relations)
          end
        override_attributes!(sg_result)
        changes_applied
        true
      end
      alias_method :save!, :save

      def mass_assign(assigned_attributes)
        sym_assigned_attributes = assigned_attributes.transform_keys(&:to_sym)
        sym_assigned_attributes.
          slice(*self.class.shotgun_writable_fetched_attributes).
          each do |k, v|
            public_send("#{k}=", v)
          end

        sym_assigned_attributes.
          slice(*self.class::BELONG_ASSOC.map{ |assoc| "#{assoc}_id".to_sym }).
          each do |k, v|
            public_send("#{k}=", v, sym_assigned_attributes["#{k.to_s.gsub(/_id$/, '')}_type".to_sym])
          end

        sym_assigned_attributes.
          slice(*self.class::BELONG_ASSOC.map(&:to_sym)).
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
          new_entity
        end

        def create!(create_attributes)
          new_entity = new
          new_entity.mass_assign(create_attributes)
          new_entity.save!
          new_entity
        end
      end

      private

      def changes_with_relations
        attribute_changes = changes.slice(*self.class.shotgun_writable_fetched_attributes).transform_values(&:last)

        belongs_to_changes = changes.slice(*self.class::BELONG_ASSOC.map{ |assoc| "#{assoc}_id" }).map do |k, _v|
          raw = k.gsub(/_id$/, '')
          [
            raw,
            { id: public_send(k), type: public_send("#{raw}_type") },
          ]
        end.to_h
        attribute_changes.merge(belongs_to_changes)
      end

      def override_attributes!(sg_result)
        new_attributes = sg_result.attributes.to_h.merge(id: sg_result.id)
        new_attributes.
          transform_keys(&:to_sym).
          slice(*self.class.shotgun_readable_fetched_attributes).
          each do |k, v|
            instance_variable_set("@#{k}", v)
          end

        new_relations = sg_result.relationships.transform_values{ |v| v["data"] }.with_indifferent_access
        self.class::BELONG_ASSOC.each do |assoc|
          next unless relation = new_relations[assoc]

          instance_variable_set("@#{assoc}_type", relation["type"])
          instance_variable_set("@#{assoc}_id", relation["id"])
          instance_variable_set("@#{assoc}", nil)
        end
      end
    end
  end
end
