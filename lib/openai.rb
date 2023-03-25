# frozen_string_literal: true

require 'concord'
require 'anima'
require 'http'

require 'openai/version'

class OpenAI
  include Concord.new(:api_key, :http)

  def initialize(api_key, http: HTTP)
    super(api_key, http)
  end
end
