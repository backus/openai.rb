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

  def initialize(...)
    super(API::Client.new(...))
  end

  def api
    API.new(api_client)
  end
end
