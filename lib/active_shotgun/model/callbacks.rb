# frozen_string_literal: true

module ActiveShotgun
  module Model
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
  end
end
