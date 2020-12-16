# frozen_string_literal: true

module ActiveShotgun
  module Model
    module Validations
      def save
        validate && super
      end

      def save!
        validate!
        super
      end
    end
  end
end
