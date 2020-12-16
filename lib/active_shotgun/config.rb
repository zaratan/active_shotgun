# frozen_string_literal: true

require 'singleton'
require 'forwardable'

module ActiveShotgun
  class Config
    DEFAULT_CONFIG = {
      shotgun_site_name: 'pasind3-prod',
      shotgun_site_url: nil,
      shotgun_client_id: nil,
      shotgun_client_secret: nil,
    }.freeze

    include Singleton

    def initialize
      @config = Struct.new(*DEFAULT_CONFIG.keys).new(*DEFAULT_CONFIG.values)
    end
    attr_reader :config

    class << self
      extend Forwardable
      # Remove the need to call .instance everywhere
      def_delegators(
        :instance,
        :configure,
        *DEFAULT_CONFIG.keys.flat_map{ |key| [key, "#{key}="] }
      )
    end

    extend Forwardable
    def_delegators(
      :config,
      *DEFAULT_CONFIG.keys.flat_map{ |key| [key, "#{key}="] }
    )

    def configure(&block)
      return unless block

      yield(@config)
    end
  end
end
