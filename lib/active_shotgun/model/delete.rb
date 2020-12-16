# frozen_string_literal: true

module ActiveShotgun
  module Model
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
  end
end
