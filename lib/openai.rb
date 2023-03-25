# frozen_string_literal: true

require 'concord'
require 'anima'
require 'abstract_type'
require 'http'
require 'addressable'
require 'ice_nine'
require 'tiktoken_ruby'

require 'openai/tokenizer'
require 'openai/chat'
require 'openai/api'
require 'openai/api/cache'
require 'openai/api/client'
require 'openai/api/resource'
require 'openai/api/response'
require 'openai/version'

class OpenAI
  include Concord.new(:api_client)

  ROOT = Pathname.new(__dir__).parent.expand_path.freeze

  def self.create(api_key, cache: nil)
    client = API::Client.new(api_key)

    if cache.is_a?(Pathname) && cache.directory?
      client = API::Cache.new(
        client,
        API::Cache::Strategy::FileSystem.new(cache)
      )
    end

    new(client)
  end

  private_class_method :new

  def api
    API.new(api_client)
  end

  def tokenizer
    Tokenizer.new
  end
  alias tokens tokenizer

  def chat(model:, history: [], **kwargs)
    Chat.new(api: api, settings: kwargs.merge(model: model), messages: history)
  end
end
