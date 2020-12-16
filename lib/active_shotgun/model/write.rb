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
  end
end
