# frozen_string_literal: true

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'
require 'ice_nine'

require 'openai/api'
require 'openai/api/client'
require 'openai/api/resource'
require 'openai/api/response'
require 'openai/version'

class OpenAI
  include Concord.new(:api_client)

  def self.create(api_key)
    new(API::Client.new(api_key))
  end

  private_class_method :new

  def api
    API.new(api_client)
  end
end
