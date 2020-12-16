# frozen_string_literal: true

require 'singleton'
require 'forwardable'

require 'shotgun_api_ruby'

module ActiveShotgun
  class Client
    include Singleton
    CONNECTION_TYPES = ["multi_entity", "entity"].freeze
    READ_ONLY_TYPES = ["image", "summary"].freeze

    def initialize
      @shotgun = ShotgunApiRuby.new(
        shotgun_site: Config.shotgun_site_name || Config.shotgun_site_url,
        auth: { client_id: Config.shotgun_client_id, client_secret: Config.shotgun_client_secret }
      )
    end
    attr_reader :shotgun

    class << self
      extend Forwardable
      # Remove the need to call .instance everywhere
      def_delegators(
        :instance,
        :shotgun,
        :fetch_field_names_for_an_entity_type
      )
    end

    def fetch_field_names_for_an_entity_type(type)
      result = shotgun.entities(type).fields.to_h
      {
        writable: result.reject do |_, v|
          (CONNECTION_TYPES + READ_ONLY_TYPES).include?(v.data_type) ||
            !v.editable
        end.keys,
        readable: result.reject{ |_, v| CONNECTION_TYPES.include?(v.data_type) }.keys,
      }
    end
  end
end
